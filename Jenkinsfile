pipeline {
  agent any

  environment {
    SHELL         = "/bin/bash"

    AWS_REGION    = "us-east-1"
    ECR_REGISTRY  = "576290270995.dkr.ecr.us-east-1.amazonaws.com"
    ECR_REPO      = "my-node-app"
    INSTANCE_ID   = "i-0e2c8e55425432246"

    BUILD_TAG     = "build-${env.BUILD_NUMBER}"
    STABLE_TAG    = "stable"

    SONAR_KEY     = "jenkins-node-ci"        // matches sonar-project.properties
    APP_URL       = "http://54.90.229.18/"
  }

  options { timestamps(); ansiColor('xterm') }

  stages {

    stage('Checkout') {
      steps {
        deleteDir()
        git branch: 'master', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
        // ensure scripts are executable (in case git perms didn’t apply)
        sh 'chmod +x scripts/*.sh || true'
      }
    }

    stage('Quality & Tests') {
      steps {
        sh '''#!/bin/bash
          set -euo pipefail
          if ! npm ci --no-audit --no-fund; then
            echo "npm ci failed. Falling back to npm install..."
            npm install --no-audit --no-fund
          fi
          npm test -- --timeout 5000 --exit --coverage
        '''

        // Ping SonarQube first; if down, mark UNSTABLE and skip analysis.
        script {
          def sonarUp = sh(returnStatus: true, script: '''
            curl -fsS --max-time 5 "$SONAR_HOST/api/system/health" >/dev/null 2>&1
          ''') == 0
          if (!sonarUp) {
            echo "SonarQube seems down; skipping analysis and marking UNSTABLE."
            currentBuild.result = 'UNSTABLE'
          } else {
            withSonarQubeEnv(installationName: 'SonarQube', credentialsId: 'sonarqube-token') {
              sh '''#!/bin/bash
                set -euo pipefail
                sonar-scanner \
                  -Dsonar.projectKey=$SONAR_KEY \
                  -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
              '''
            }
            // Only wait for QG if the scanner succeeded and created report-task.txt
            script {
              def hasReport = fileExists("${env.WORKSPACE}/.scannerwork/report-task.txt") || fileExists('report-task.txt')
              if (hasReport) {
                timeout(time: 12, unit: 'MINUTES') {
                  waitForQualityGate abortPipeline: true
                }
              } else {
                echo "No report-task.txt found; skipping waitForQualityGate."
                currentBuild.result = currentBuild.result ?: 'UNSTABLE'
              }
            }
          }
        }
      }
    }

    stage('Security Scan (Trivy FS)') {
      steps {
        sh '''#!/bin/bash
          set -euo pipefail
          trivy fs --exit-code 1 --severity HIGH,CRITICAL,MEDIUM \
            --format template --template "@contrib/html.tpl" -o trivy-report.html .
        '''
      }
      post { always { archiveArtifacts artifacts: 'trivy-report.html', fingerprint: true } }
    }

    stage('Docker Build & Image Scan') {
      steps {
        sh '''#!/bin/bash
          set -euo pipefail
          docker build -t $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG .
          trivy image --severity HIGH,CRITICAL --no-progress $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG || true
        '''
      }
    }

    stage('Push to ECR') {
      steps {
        script {
          withDockerRegistry([credentialsId: 'ecr:us-east-1:aws-credentials', url: "https://${ECR_REGISTRY}"]) {
            sh '''#!/bin/bash
              set -euo pipefail
              docker push $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG
            '''
          }
        }
      }
    }

    stage('Deploy to EC2 (via SSM)') {
      when { branch 'master' }
      steps {
        script {
          withDockerRegistry([credentialsId: 'ecr:us-east-1:aws-credentials', url: "https://${ECR_REGISTRY}"]) {
            sh '''#!/bin/bash
              set -euo pipefail
              aws ssm send-command \
                --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
                --document-name "AWS-RunShellScript" \
                --comment "Deploy Node App" \
                --region ${AWS_REGION} \
                --parameters '{"commands":["docker pull '"$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG"'","docker stop app || true","docker rm app || true","docker run -d --name app -p 80:3000 --restart unless-stopped '"$ECR_REGISTRY/$ECR_REPO:$BUILD_TAG"'"]}'
            '''
          }
        }
      }
    }

    stage('Healthcheck & (possible) Rollback') {
      when { branch 'master' }
      steps {
        script {
          def rc = sh(returnStatus: true, script: '''#!/bin/bash
            set -euo pipefail
            for i in {1..24}; do
              if curl -fsS "$APP_URL" >/dev/null; then
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
            echo "⚠️ Rolling back to last good image (stable)..."
            withDockerRegistry([credentialsId: 'ecr:us-east-1:aws-credentials', url: "https://${ECR_REGISTRY}"]) {
              sh '''#!/bin/bash
                set -euo pipefail
                docker pull ${ECR_REGISTRY}/${ECR_REPO}:${STABLE_TAG}
                CMD_ID=$(aws ssm send-command \
                  --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
                  --document-name "AWS-RunShellScript" \
                  --region ${AWS_REGION} \
                  --parameters '{"commands":["docker pull '"$ECR_REGISTRY/$ECR_REPO:$STABLE_TAG"'","docker stop app || true","docker rm app || true","docker run -d --name app -p 80:3000 --restart unless-stopped '"$ECR_REGISTRY/$ECR_REPO:$STABLE_TAG"'"]}' \
                  --query 'Command.CommandId' --output text)
                # Polling for SSM command status
                for i in {1..60}; do
                  STATUS=$(aws ssm list-command-invocations --command-id "$CMD_ID" --details \
                    --region ${AWS_REGION} --query 'CommandInvocations[0].Status' --output text)
                  echo "Rollback SSM status: $STATUS"
                  [[ "$STATUS" == "Success" ]] && break
                  [[ "$STATUS" == "Failed" || "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" ]] && exit 1
                  sleep 5
                done
              '''
            }
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
        script {
          withDockerRegistry([credentialsId: 'ecr:us-east-1:aws-credentials', url: "https://${ECR_REGISTRY}"]) {
            sh '''#!/bin/bash
              set -euo pipefail
              docker tag $ECR_REGISTRY/$ECR_REPO:$BUILD_TAG $ECR_REGISTRY/$ECR_REPO:$STABLE_TAG
              docker push $ECR_REGISTRY/$ECR_REPO:$STABLE_TAG
            '''
          }
        }
      }
    }
  }

  post {
    always {
      sh 'docker system prune -af || true'
    }

    // small wrapper to avoid duplication and prevent Groovy interpolation of secret
    success {
      script {
        withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
          sh(label: 'notify-success', script: '''
            scripts/notify.sh success "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"
          ''')
        }
      }
    }
    failure {
      script {
        withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
          sh(label: 'notify-failure', script: '''
            scripts/notify.sh failure "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"
          ''')
        }
      }
    }
    unstable {
      script {
        withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
          sh(label: 'notify-unstable', script: '''
            scripts/notify.sh unstable "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"
          ''')
        }
      }
    }
    aborted {
      script {
        withCredentials([string(credentialsId: 'Slack-CI-CD', variable: 'SLACK_URL')]) {
          sh(label: 'notify-aborted', script: '''
            scripts/notify.sh aborted "$JOB_NAME" "$BUILD_NUMBER" "$SLACK_URL"
          ''')
        }
      }
    }
  }
}
