pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
    disableConcurrentBuilds()
  }

  environment {
    AWS_REGION   = "us-east-1"
    ECR_REGISTRY = "576290270995.dkr.ecr.us-east-1.amazonaws.com"
    ECR_REPO     = "my-node-app"

    INSTANCE_ID  = "i-0e2c8e55425432246"

    BUILD_TAG    = "build-${env.BUILD_NUMBER}"
    STABLE_TAG   = "stable"

    SONAR_KEY    = "jenkins-node-ci"
    APP_URL      = "http://3.80.104.209/"
    
    TRIVY_DISABLE_VEX_NOTICE = "true"
  }

  stages {

    stage('Checkout') {
      steps {
        deleteDir()
        git branch: 'master', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
        script {
          // capture git metadata for injection
          env.GIT_COMMIT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          env.GIT_BRANCH = sh(returnStdout: true, script: "git rev-parse --abbrev-ref HEAD").trim()
          env.GIT_AUTHOR = sh(returnStdout: true, script: "git log -1 --pretty=format:'%an'").trim()
          env.GIT_MESSAGE = sh(returnStdout: true, script: "git log -1 --pretty=format:'%s'").trim()
          env.GIT_DATE = sh(returnStdout: true, script: "git log -1 --date=iso --pretty=format:'%ad'").trim()
        }
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
          TEMPLATE=""
          if [ -f "/usr/local/share/trivy/templates/html.tpl" ]; then
            TEMPLATE="@/usr/local/share/trivy/templates/html.tpl"
          elif [ -f "/root/.cache/trivy/templates/html.tpl" ]; then
            TEMPLATE="@/root/.cache/trivy/templates/html.tpl"
          fi

          if [ -n "$TEMPLATE" ]; then
            trivy fs --exit-code 1 --severity HIGH,CRITICAL,MEDIUM \
              --format template --template "$TEMPLATE" \
              -o trivy-report.html .
          else
            trivy fs --exit-code 1 --severity HIGH,CRITICAL,MEDIUM \
              --format table -o trivy-report.txt .
          fi
        '''
        archiveArtifacts artifacts: 'trivy-report.*', fingerprint: true
      }
    }

    stage('Docker Build & Push') {
      steps {
        sh '''#!/bin/bash
          set -euo pipefail
          aws ecr get-login-password --region "$AWS_REGION" | \
            docker login --username AWS --password-stdin "$ECR_REGISTRY"

          # Enable BuildKit for faster builds
          DOCKER_BUILDKIT=1 docker build -t "$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG" .

          # (Optional) Scan built image (non-blocking)
          trivy image --severity HIGH,CRITICAL --no-progress "$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG" || true

          docker push "$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG"
        '''
      }
    }

        stage('Deploy to EC2 (via SSM)') {
          steps {
            sh '''#!/bin/bash
              set -euo pipefail
        
              PARAMS=$(cat <<EOF
        {"commands":[
          "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY",
          "docker pull $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG",
          "docker stop app || true",
          "docker rm app || true",
          "docker run -d --name app -p 80:3000 --restart unless-stopped \
             -e BUILD_NUMBER=$BUILD_NUMBER \
             -e GIT_DATE=\\"$GIT_DATE\\" \
             -e GIT_BRANCH=$GIT_BRANCH \
             -e GIT_COMMIT=$GIT_COMMIT \
             -e GIT_AUTHOR=\\"$GIT_AUTHOR\\" \
             -e GIT_MESSAGE=\\"$GIT_MESSAGE\\" \
             $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG"
        ]}
        EOF
        )
        
              CMD_ID=$(aws ssm send-command \
                --document-name "AWS-RunShellScript" \
                --comment "Deploy Node App" \
                --region "$AWS_REGION" \
                --targets "Key=InstanceIds,Values=$INSTANCE_ID" \
                --parameters "$PARAMS" \
                --query "Command.CommandId" --output text)
        
              for i in {1..60}; do
                STATUS=$(aws ssm list-command-invocations --command-id "$CMD_ID" --details --region "$AWS_REGION" --query "CommandInvocations[0].Status" --output text)
                echo "Deploy SSM status: $STATUS (poll $i/60)"
                if [[ "$STATUS" == "Success" ]]; then exit 0; fi
                if [[ "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" || "$STATUS" == "Failed" ]]; then exit 1; fi
                sleep 5
              done
        
              echo "SSM deploy timed out"
              exit 1
            '''
          }
        }

    stage('Healthcheck & Rollback') {
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
              sleep 10
            done
            exit 1
          ''')

          if (rc != 0) {
            sh '''#!/bin/bash
              set -euo pipefail
              CMD_ID=$(aws ssm send-command \
                --document-name "AWS-RunShellScript" \
                --region "$AWS_REGION" \
                --targets "Key=InstanceIds,Values=$INSTANCE_ID" \
                --parameters commands="docker pull $ECR_REGISTRY/$ECR_REPO:$STABLE_TAG","docker stop app || true","docker rm app || true","docker run -d --name app -p 80:3000 --restart unless-stopped $ECR_REGISTRY/$ECR_REPO:$STABLE_TAG" \
                --query "Command.CommandId" --output text)

              for i in {1..60}; do
                STATUS=$(aws ssm list-command-invocations --command-id "$CMD_ID" --details --region "$AWS_REGION" --query 'CommandInvocations[0].Status' --output text)
                echo "Rollback SSM status: $STATUS"
                [[ "$STATUS" == "Success" ]] && exit 0
                [[ "$STATUS" == "Failed" || "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" ]] && exit 1
                sleep 5
              done
              exit 1
            '''
            error("Rolled back because healthcheck failed.")
          }
        }
      }
    }

    stage('Promote image to stable') {
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
      slackSend(color: 'good', message: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${env.BUILD_URL}")
    }
    failure {
      slackSend(color: 'danger', message: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${env.BUILD_URL}")
    }
    unstable {
      slackSend(color: 'warning', message: "⚠️ UNSTABLE: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${env.BUILD_URL}")
    }
    aborted {
      slackSend(color: '#AAAAAA', message: "🚫 ABORTED: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${env.BUILD_URL}")
    }
  }
}
