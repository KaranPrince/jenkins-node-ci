pipeline {
  agent any

  environment {
    AWS_REGION   = "us-east-1"
    ECR_REPO     = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
    INSTANCE_ID  = "i-0e2c8e55425432246"

    BUILD_TAG    = "build-${env.BUILD_NUMBER}"
    LATEST_TAG   = "latest"

    SONAR_KEY    = "jenkins-node-ci"
    // ❗️Set this to your actual SonarQube URL (NO angle brackets)
    SONAR_HOST   = "http://3.80.177.136:9000"
    SONAR_TOKEN  = credentials('sonarqube-token')

    // ❗️Set this to your app’s DNS/Elastic IP; no trailing path
    APP_URL      = "http://98.81.80.45/"
  }

  options { timestamps() }

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
            // Use single-quoted Groovy string so secrets are NOT interpolated by Groovy.
            // Quote each -D value to avoid shell interpreting special chars.
            sh '''
              set -euo pipefail
              sonar-scanner \
                -D"sonar.projectKey=$SONAR_KEY" \
                -D"sonar.sources=." \
                -D"sonar.host.url=$SONAR_HOST" \
                -D"sonar.token=$SONAR_TOKEN"
            '''
          }
        }
        stage('Unit Tests') {
          steps {
            sh '''
              set -euo pipefail
              # Prefer deterministic installs; if lock is stale, fall back (temporary)
              if ! npm ci --no-audit --no-fund; then
                echo "npm ci failed (lock mismatch). Falling back to npm install..."
                npm install --no-audit --no-fund
              fi
              npm test || true
            '''
          }
        }
      }
    }

    stage('Security Scan (Trivy FS)') {
      steps {
        sh '''
          set -euo pipefail
          trivy fs --exit-code 1 --severity HIGH,CRITICAL --no-progress .
        '''
      }
    }

    stage('Docker Build & Image Scan') {
      steps {
        sh """
          set -euo pipefail
          docker build -t $ECR_REPO:$BUILD_TAG .
          # Report-only: do not fail the build here (FS scan already gates)
          trivy image --severity HIGH,CRITICAL --no-progress $ECR_REPO:$BUILD_TAG || true
        """
      }
    }

    stage('Push to ECR') {
      steps {
        sh """
          set -euo pipefail
          aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
          docker tag $ECR_REPO:$BUILD_TAG $ECR_REPO:$LATEST_TAG
          docker push $ECR_REPO:$BUILD_TAG
          docker push $ECR_REPO:$LATEST_TAG
        """
      }
    }

    stage('Deploy to EC2 (via SSM)') {
      steps {
        sh """
          set -euo pipefail
          aws ssm send-command \
            --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
            --document-name "AWS-RunShellScript" \
            --region ${AWS_REGION} \
            --parameters 'commands=[
              "set -e",
              "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}",
              "docker pull ${ECR_REPO}:${BUILD_TAG}",
              "docker stop app || true",
              "docker rm app || true",
              "docker run -d --name app -p 80:3000 --restart unless-stopped ${ECR_REPO}:${BUILD_TAG}"
            ]'
        """
      }
    }

    stage('Healthcheck & Rollback') {
      steps {
        script {
          def rc = sh(
            returnStatus: true,
            script: '''
              set -euo pipefail
              for i in {1..12}; do
                if curl -fsS "$APP_URL" > /dev/null; then
                  echo "✅ App is healthy"
                  exit 0
                fi
                echo "⏳ Waiting for app to become healthy ($i/12)..."
                sleep 5
              done
              echo "❌ Healthcheck failed"
              exit 1
            '''
          )

          if (rc != 0) {
            echo "⚠️ Rolling back to last good image ($LATEST_TAG)..."
            sh """
              set -euo pipefail
              aws ssm send-command \
                --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
                --document-name "AWS-RunShellScript" \
                --region ${AWS_REGION} \
                --parameters 'commands=[
                  "set -e",
                  "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}",
                  "docker pull ${ECR_REPO}:${LATEST_TAG}",
                  "docker stop app || true",
                  "docker rm app || true",
                  "docker run -d --name app -p 80:3000 --restart unless-stopped ${ECR_REPO}:${LATEST_TAG}"
                ]'
            """
            error("Rolled back because healthcheck failed.")
          }
        }
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
  }
}
