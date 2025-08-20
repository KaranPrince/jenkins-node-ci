pipeline {
  agent any

  environment {
    AWS_REGION   = "us-east-1"
    ECR_REPO     = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
    INSTANCE_ID  = "i-0e2c8e55425432246"
    BUILD_TAG    = "build-${env.BUILD_NUMBER}"
    LATEST_TAG   = "latest"

    SONAR_KEY    = "jenkins-node-ci"
    SONAR_HOST   = "http://3.80.177.136:9000"
    SONAR_TOKEN  = credentials('sonarqube-token')

    // app endpoint for smoke test
    APP_URL      = "http://98.81.80.45/"
  }

  options { timestamps() }

  stages {
    stage('Workspace Reset') {
      steps {
        echo "🧹 Resetting workspace..."
        deleteDir()
      }
    }

    stage('Checkout Code') {
      steps {
        echo "🔄 Checking out source code..."
        git branch: 'master', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
      }
    }

    stage('IaC: Terraform (fmt/validate/plan)') {
      when {
        expression { fileExists('infra/main.tf') }
      }
      steps {
        echo "🏗️ Running Terraform checks..."
        dir('infra') {
          sh '''
            set -e
            terraform --version || true
            terraform init -input=false
            terraform fmt -check
            terraform validate
            terraform plan -input=false -out=tfplan
          '''
        }
      }
    }

    stage('Quality & Tests') {
      parallel {
        stage('Code Quality (SonarQube)') {
          steps {
            echo "🔎 Running SonarQube analysis..."
            sh """
              sonar-scanner \
                -Dsonar.projectKey=$SONAR_KEY \
                -Dsonar.sources=. \
                -Dsonar.host.url=$SONAR_HOST \
                -Dsonar.token=$SONAR_TOKEN
            """
          }
        }

        stage('Run Tests') {
          steps {
            echo "🧪 Running unit tests..."
            sh '''
              set -e
              rm -rf node_modules package-lock.json || true
              npm ci --no-audit --no-fund || npm install
              npm test || true
            '''
          }
        }
      }
    }

    stage('Trivy FS Scan (source & deps)') {
      steps {
        echo "🔐 Running Trivy filesystem scan..."
        sh '''
          set -e
          trivy --version || true
          # Fail pipeline on HIGH/CRITICAL in the repo (package.json lockfiles, etc.)
          trivy fs --exit-code 1 --severity HIGH,CRITICAL --no-progress .
        '''
      }
    }

    stage('Docker Build & Image Scan') {
      steps {
        echo "🐳 Building Docker image and scanning with Trivy..."
        sh """
          docker build --no-cache -t $ECR_REPO:$BUILD_TAG .
          # Image scan: do not fail the build here (report only); FS scan already gates
          trivy image --severity HIGH,CRITICAL --no-progress $ECR_REPO:$BUILD_TAG || true
        """
      }
    }

    stage('Push to ECR') {
      steps {
        echo "📤 Pushing image to ECR..."
        sh """
          aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
          docker tag $ECR_REPO:$BUILD_TAG $ECR_REPO:$LATEST_TAG
          docker push $ECR_REPO:$BUILD_TAG
          docker push $ECR_REPO:$LATEST_TAG
        """
      }
    }

    stage('Capture Current Image (for rollback)') {
      steps {
        echo "📸 Capturing currently running image on EC2..."
        script {
          // Ask the instance (via SSM) which image the 'app' container is running
          def commandId = sh(
            returnStdout: true,
            script: """
              aws ssm send-command \
                --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
                --document-name "AWS-RunShellScript" \
                --region ${AWS_REGION} \
                --parameters 'commands=["docker inspect --format={{.Config.Image}} app 2>/dev/null || echo \\"${ECR_REPO}:${LATEST_TAG}\\""]' \
                --query "Command.CommandId" \
                --output text
            """
          ).trim()

          // Give SSM a moment, then fetch the output
          sleep time: 6, unit: 'SECONDS'

          def prevImage = sh(
            returnStdout: true,
            script: """
              aws ssm get-command-invocation \
                --region ${AWS_REGION} \
                --command-id ${commandId} \
                --instance-id ${INSTANCE_ID} \
                --query 'StandardOutputContent' \
                --output text | tr -d '\\r' | tail -n1
            """
          ).trim()

          if (!prevImage) { prevImage = "${ECR_REPO}:${LATEST_TAG}" }
          echo "Previous image detected: ${prevImage}"
          env.PREV_IMAGE = prevImage
        }
      }
    }

    stage('Deploy to EC2 (via SSM)') {
      steps {
        echo "🚀 Deploying build ${BUILD_NUMBER} to EC2..."
        script {
          def branch  = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
          def commit  = sh(script: "git rev-parse HEAD",             returnStdout: true).trim()
          def author  = sh(script: "git log -1 --pretty=format:%an", returnStdout: true).trim()
          def date    = sh(script: "git log -1 --date=iso-strict --pretty=format:%cd", returnStdout: true).trim()
          def message = sh(script: "git log -1 --pretty=format:%s",  returnStdout: true).trim()

          sh """
            aws ssm send-command \
              --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
              --document-name "AWS-RunShellScript" \
              --comment "Deploy ${BUILD_TAG}" \
              --region ${AWS_REGION} \
              --parameters 'commands=[
                "set -e",
                "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}",
                "docker pull ${ECR_REPO}:${BUILD_TAG}",
                "docker stop app || true",
                "docker rm app || true",
                "docker run -d --name app -p 80:3000 --restart unless-stopped \
                  -e BUILD_NUMBER=${BUILD_NUMBER} \
                  -e GIT_BRANCH=${branch} \
                  -e GIT_COMMIT=${commit} \
                  -e GIT_AUTHOR=${author} \
                  -e GIT_DATE=${date} \
                  -e GIT_MESSAGE=${message} \
                  -e ENVIRONMENT=prod \
                  ${ECR_REPO}:${BUILD_TAG}"
              ]'
          """
        }
      }
    }

    stage('Automated Healthcheck & Rollback') {
      steps {
        echo "🩺 Healthchecking & rolling back on failure if needed..."
        script {
          // Simple retrying smoke test against APP_URL
          def rc = sh(
            returnStatus: true,
            script: '''
              set -e
              for i in {1..12}; do
                if curl -fsS "$APP_URL" > /dev/null; then
                  echo "✅ App is healthy"
                  exit 0
                fi
                echo "⏳ Waiting for app to become healthy ($i/12)..."
                sleep 10
              done
              echo "❌ Healthcheck failed"
              exit 1
            '''
          )

          if (rc != 0) {
            echo "⚠️ Healthcheck failed — rolling back to ${env.PREV_IMAGE}"
            sh """
              aws ssm send-command \
                --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
                --document-name "AWS-RunShellScript" \
                --comment "Rollback to ${env.PREV_IMAGE}" \
                --region ${AWS_REGION} \
                --parameters 'commands=[
                  "set -e",
                  "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}",
                  "docker pull ${env.PREV_IMAGE}",
                  "docker stop app || true",
                  "docker rm app || true",
                  "docker run -d --name app -p 80:3000 --restart unless-stopped ${env.PREV_IMAGE}"
                ]'
            """
            error("Rolled back to previous image because healthcheck failed.")
          }
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline completed successfully (build #${env.BUILD_NUMBER})"
    }
    failure {
      echo "❌ Pipeline failed."
    }
    always {
      echo "🧹 Cleaning up Docker junk..."
      sh 'docker system prune -af || true'
    }
  }
}
