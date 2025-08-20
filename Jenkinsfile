pipeline {
  agent any

  environment {
    SHELL        = "/bin/bash"

    AWS_REGION   = "us-east-1"
    ECR_REPO     = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
    INSTANCE_ID  = "i-0e2c8e55425432246"

    BUILD_TAG    = "build-${env.BUILD_NUMBER}"
    STABLE_TAG   = "stable"   // promoted only after healthcheck passes

    SONAR_KEY    = "jenkins-node-ci"
    SONAR_HOST   = "http://3.80.177.136:9000"
    SONAR_TOKEN  = credentials('sonarqube-token')

    APP_URL      = "http://98.81.80.45/"
  }

  options { timestamps(); ansiColor('xterm') }

  stages {

    stage('Checkout') {
      steps {
        deleteDir()
        git branch: 'master', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
      }
    }

    stage('Quality & Tests') {
      parallel {
        stage('SonarQube') {
          steps {
            sh '''#!/usr/bin/env bash
              set -euo pipefail
              sonar-scanner \
                -D"sonar.projectKey=$SONAR_KEY" \
                -D"sonar.host.url=$SONAR_HOST" \
                -D"sonar.token=$SONAR_TOKEN"
            '''
            // If your agent doesn't have the CLI, use the Jenkins Sonar plugin or `npx sonarqube-scanner`.
          }
        }
        stage('Unit Tests') {
          steps {
            sh '''#!/usr/bin/env bash
              set -euo pipefail
              if ! npm ci --no-audit --no-fund; then
                echo "npm ci failed (lock mismatch). Falling back to npm install..."
                npm install --no-audit --no-fund
              fi
              npm test
            '''
          }
        }
      }
    }

    stage('Security Scan (Trivy FS)') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          trivy fs --exit-code 1 --severity HIGH,CRITICAL --no-progress .
        '''
      }
    }

    stage('Docker Build & Image Scan') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          docker build -t $ECR_REPO:$BUILD_TAG .
          # Report-only image scan (FS scan above already gates)
          trivy image --severity HIGH,CRITICAL --no-progress $ECR_REPO:$BUILD_TAG || true
        '''
      }
    }

    stage('Push to ECR') {
      steps {
        // If you don't use an instance profile, wrap this stage in withCredentials for AWS keys.
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          aws ecr get-login-password --region $AWS_REGION \
            | docker login --username AWS --password-stdin $ECR_REPO
          docker push $ECR_REPO:$BUILD_TAG
        '''
      }
    }

    stage('Deploy to EC2 (via SSM)') {
  steps {
    sh '''#!/usr/bin/env bash
      set -euo pipefail
      aws ssm send-command \
        --targets "Key=instanceIds,Values=${INSTANCE_ID}" \
        --document-name "AWS-RunShellScript" \
        --comment "Deploy Node App" \
        --region ${AWS_REGION} \
        --parameters '{"commands":[
          "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}",
          "docker pull ${ECR_REPO}:${BUILD_TAG}",
          "docker stop app || true",
          "docker rm app || true",
          "docker run -d --name app -p 80:3000 --restart unless-stopped ${ECR_REPO}:${BUILD_TAG}"
        ]}'
    '''
  }
}
    
    stage('Healthcheck & (possible) Rollback') {
      steps {
        script {
          def rc = sh(returnStatus: true, script: '''#!/usr/bin/env bash
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
            echo "⚠️ Rolling back to last good image (stable)..."
            sh '''#!/usr/bin/env bash
              set -euo pipefail
              CMD_ID=$(aws ssm send-command \
                --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
                --document-name "AWS-RunShellScript" \
                --region ${AWS_REGION} \
                --parameters 'commands=[
                  "set -e",
                  "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}",
                  "docker pull ${ECR_REPO}:${STABLE_TAG}",
                  "docker stop app || true",
                  "docker rm app || true",
                  "docker run -d --name app -p 80:3000 --restart unless-stopped ${ECR_REPO}:${STABLE_TAG}"
                ]' \
                --query 'Command.CommandId' --output text)

              for i in {1..60}; do
                STATUS=$(aws ssm list-command-invocations --command-id "$CMD_ID" --details \
                  --region ${AWS_REGION} --query 'CommandInvocations[0].Status' --output text)
                echo "Rollback SSM status: $STATUS"
                [[ "$STATUS" == "Success" ]] && break
                [[ "$STATUS" == "Failed" || "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" ]] && exit 1
                sleep 5
              done
            '''
            error("Rolled back because healthcheck failed.")
          }
        }
      }
    }

    stage('Promote image to stable') {
      when { expression { currentBuild.currentResult == 'SUCCESS' } }
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          aws ecr get-login-password --region $AWS_REGION \
            | docker login --username AWS --password-stdin $ECR_REPO
          docker tag $ECR_REPO:$BUILD_TAG $ECR_REPO:$STABLE_TAG
          docker push $ECR_REPO:$STABLE_TAG
        '''
      }
    }
  }

  post {
    always {
      sh 'docker system prune -af || true'
    }
    success {
      echo "✅ Pipeline completed successfully (build #${env.BUILD_NUMBER})"
    }
    failure {
      echo "❌ Pipeline failed."
    }
    unstable {
      echo "⚠️ Pipeline unstable."
    }
    aborted {
      echo "🚫 Pipeline aborted."
    }
  }
}
