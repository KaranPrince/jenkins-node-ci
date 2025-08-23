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
    APP_URL      = "http://3.80.104.209/"
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
          # Prefer HTML report if template exists, otherwise fallback to table
          if trivy -h | grep -q "@contrib/html.tpl" && [ -f "$(trivy -v >/dev/null 2>&1; echo)" ]; then
            true # no-op to avoid set -e nuisance
          fi

          if [ -f "/usr/local/share/trivy/templates/html.tpl" ]; then
            TEMPLATE="@/usr/local/share/trivy/templates/html.tpl"
          elif [ -f "/root/.cache/trivy/templates/html.tpl" ]; then
            TEMPLATE="@/root/.cache/trivy/templates/html.tpl"
          elif [ -f "$(dirname "$(which trivy 2>/dev/null)")/../share/trivy/templates/html.tpl" ]; then
            TEMPLATE="@$(dirname "$(which trivy)")/../share/trivy/templates/html.tpl"
          else
            TEMPLATE=""
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

          # Login to ECR (requires either instance profile or env creds)
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
  steps {
    sh '''#!/bin/bash
      set -euo pipefail

      # Send command: first login to ECR on the instance, then pull + run
      CMD_ID=$(aws ssm send-command \
        --document-name "AWS-RunShellScript" \
        --comment "Deploy Node App" \
        --region "$AWS_REGION" \
        --targets "Key=InstanceIds,Values=$INSTANCE_ID" \
        --parameters commands="aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY","docker pull $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG","docker stop app || true","docker rm app || true","docker run -d --name app -p 80:3000 --restart unless-stopped $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG" \
        --query "Command.CommandId" --output text)

      echo "SSM CommandId: $CMD_ID" > cmd.txt

      # Poll and emit stdout/stderr for debugging (prints output every poll)
      for i in {1..60}; do
        STATUS=$(aws ssm list-command-invocations --command-id "$CMD_ID" --details --region "$AWS_REGION" --query "CommandInvocations[0].Status" --output text)
        echo "Deploy SSM status: $STATUS (poll $i/60)"

        # Try to print remote stdout/err so Jenkins log contains failure reason
        aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" --region "$AWS_REGION" --query "StandardOutputContent" --output text || true
        aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" --region "$AWS_REGION" --query "StandardErrorContent" --output text || true

        if [[ "$STATUS" == "Success" ]]; then
          exit 0
        fi
        if [[ "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" || "$STATUS" == "Failed" ]]; then
          # we've already printed stdout/err above — fail the job
          exit 1
        fi
        sleep 5
      done

      echo "SSM deploy timed out"
      exit 1
    '''
  }
}

    stage('Healthcheck & (possible) Rollback') {
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

              aws ecr get-login-password --region "$AWS_REGION" | \
                docker login --username AWS --password-stdin "$ECR_REGISTRY"

              docker pull "$ECR_REGISTRY/$ECR_REPO:$STABLE_TAG" || {
  echo "No stable image found in ECR ($STABLE_TAG) — cannot rollback automatically"
  exit 1
}

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

              echo "Rollback SSM timed out"
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
      withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
        sh 'scripts/notify.sh success "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"'
      }
    }
    failure {
      withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
        sh 'scripts/notify.sh failure "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"'
      }
    }
    unstable {
      withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
        sh 'scripts/notify.sh unstable "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"'
      }
    }
    aborted {
      withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
        sh 'scripts/notify.sh aborted "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"'
      }
    }
  }
}
