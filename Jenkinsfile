pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
    disableConcurrentBuilds()
  }

  environment {
    SHELL        = "/bin/bash"

    // --- AWS/ECR ---
    AWS_REGION   = "us-east-1"
    ECR_REGISTRY = "576290270995.dkr.ecr.us-east-1.amazonaws.com"
    ECR_REPO     = "my-node-app"

    // --- EC2/SSM deploy target ---
    INSTANCE_ID  = "i-0e2c8e55425432246"

    // --- Image tags ---
    BUILD_TAG    = "build-${env.BUILD_NUMBER}"
    STABLE_TAG   = "stable"

    // --- SonarQube ---
    SONAR_KEY    = "jenkins-node-ci"

    // --- App health URL (your web server) ---
    APP_URL      = "http://54.90.229.18/"
  }

  stages {

    stage('Checkout') {
      steps {
        deleteDir()
        git branch: 'master', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
      }
    }

    stage('Quality & Tests') {
      steps {
        sh '''#!/bin/bash
          set -euo pipefail
          npm ci --no-audit --no-fund || npm install --no-audit --no-fund
          npm test -- --coverage
        '''

        withSonarQubeEnv('SonarQube') {
          sh '''#!/bin/bash
            set -euo pipefail
            sonar-scanner \
              -Dsonar.projectKey="$SONAR_KEY" \
              -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
          '''
        }

        timeout(time: 12, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Security Scan (Trivy FS)') {
      steps {
        sh '''#!/bin/bash
          set -euo pipefail
          trivy fs --exit-code 1 --severity HIGH,CRITICAL,MEDIUM \
            --format template --template "@contrib/html.tpl" \
            -o trivy-report.html .
        '''
        archiveArtifacts artifacts: 'trivy-report.html', fingerprint: true
      }
    }

    stage('Docker Build & Push') {
      steps {
        sh '''#!/bin/bash
          set -euo pipefail

          # Login to ECR
          aws ecr get-login-password --region "$AWS_REGION" | \
            docker login --username AWS --password-stdin "$ECR_REGISTRY"

          # Build
          docker build -t "$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG" .

          # (Optional) Image scan - report only
          trivy image --severity HIGH,CRITICAL --no-progress "$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG" || true

          # Push
          docker push "$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG"
        '''
      }
    }

    stage('Deploy to EC2 (via SSM)') {
      when { branch 'master' }
      steps {
        sh '''#!/bin/bash
          set -euo pipefail

          # Send SSM command. Use --parameters commands="cmd1","cmd2",... so our variables expand here.
          aws ssm send-command \
            --document-name "AWS-RunShellScript" \
            --comment "Deploy Node App" \
            --region "$AWS_REGION" \
            --targets "Key=InstanceIds,Values=$INSTANCE_ID" \
            --parameters commands="docker pull $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG","docker stop app || true","docker rm app || true","docker run -d --name app -p 80:3000 --restart unless-stopped $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG" \
            --query "Command.CommandId" --output text > cmd.txt

          CMD_ID=$(cat cmd.txt)

          # Poll SSM invocation status
          for i in {1..60}; do
            STATUS=$(aws ssm list-command-invocations --command-id "$CMD_ID" --details --region "$AWS_REGION" --query "CommandInvocations[0].Status" --output text)
            echo "Deploy SSM status: $STATUS"
            if [[ "$STATUS" == "Success" ]]; then exit 0; fi
            if [[ "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" || "$STATUS" == "Failed" ]]; then exit 1; fi
            sleep 5
          done

          echo "SSM deploy timed out"
          exit 1
        '''
      }
    }

    stage('Healthcheck & (possible) Rollback') {
      when { branch 'master' }
      steps {
        script {
          def rc = sh(returnStatus: true, script: '''#!/bin/bash
            set -euo pipefail
            for i in {1..24}; do
              if curl -fsS "$APP_URL" > /dev/null; then
                echo "✅ App is healthy"
                exit 0
              fi
              echo "⏳ Waiting for app to become healthy ($i/24)..."
              sleep 5
            done
            echo "❌ Healthcheck failed"
            exit 1
          ''')

          if (rc != 0) {
            echo "⚠️ Rolling back to last good image ($STABLE_TAG)..."
            sh '''#!/bin/bash
              set -euo pipefail

              # Login (safe even if already logged in)
              aws ecr get-login-password --region "$AWS_REGION" | \
                docker login --username AWS --password-stdin "$ECR_REGISTRY"

              docker pull "$ECR_REGISTRY/$ECR_REPO:$STABLE_TAG"

              CMD_ID=$(aws ssm send-command \
                --document-name "AWS-RunShellScript" \
                --region "$AWS_REGION" \
                --targets "Key=InstanceIds,Values=$INSTANCE_ID" \
                --parameters commands="docker pull $ECR_REGISTRY/$ECR_REPO:$STABLE_TAG","docker stop app || true","docker rm app || true","docker run -d --name app -p 80:3000 --restart unless-stopped $ECR_REGISTRY/$ECR_REPO:$STABLE_TAG" \
                --query "Command.CommandId" --output text)

              # Poll rollback status
              for i in {1..60}; do
                STATUS=$(aws ssm list-command-invocations --command-id "$CMD_ID" --details --region "$AWS_REGION" --query 'CommandInvocations[0].Status' --output text)
                echo "Rollback SSM status: $STATUS"
                [[ "$STATUS" == "Success" ]] && exit 0
                [[ "$STATUS" == "Failed" || "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" ]] && exit 1
                sleep 5
              done

              echo "Rollback SSM timed out"
              exit 1
            '''
            error("Rolled back because healthcheck failed.")
          }
        }
      }
    }

    stage('Promote image to stable') {
      when {
        allOf {
          branch 'master'
          expression { currentBuild.currentResult == 'SUCCESS' }
        }
      }
      steps {
        sh '''#!/bin/bash
          set -euo pipefail
          aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
          docker pull "$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG"
          docker tag "$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG" "$ECR_REGISTRY/$ECR_REPO:$STABLE_TAG"
          docker push "$ECR_REGISTRY/$ECR_REPO:$STABLE_TAG"
        '''
      }
    }
  }

  post {
    always {
      sh 'docker system prune -af || true'
    }
    success {
      withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
        sh '''#!/bin/bash
          scripts/notify.sh success "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"
        '''
      }
    }
    failure {
      withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
        sh '''#!/bin/bash
          scripts/notify.sh failure "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"
        '''
      }
    }
    unstable {
      withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
        sh '''#!/bin/bash
          scripts/notify.sh unstable "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"
        '''
      }
    }
    aborted {
      withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
        sh '''#!/bin/bash
          scripts/notify.sh aborted "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"
        '''
      }
    }
  }
}
