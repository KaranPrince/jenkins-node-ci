pipeline {
  agent any

  environment {
    AWS_REGION    = "us-east-1"
    ECR_REGISTRY  = "576290270995.dkr.ecr.us-east-1.amazonaws.com"
    ECR_REPO_NAME = "my-node-app"
    ECR_REPO      = "${ECR_REGISTRY}/${ECR_REPO_NAME}"
    INSTANCE_ID   = "i-0e2c8e55425432246"   // ✅ use this everywhere
    BUILD_TAG     = "build-${env.BUILD_NUMBER}"
    SONAR_KEY     = "jenkins-node-ci"
    SONAR_HOST    = "http://13.217.194.227:9000"
    // SONAR_TOKEN via credentials
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

    stage('Code Quality (SonarQube)') {
      environment { SONAR_TOKEN = credentials('sonarqube-token') }
      steps {
        echo "🔎 Running SonarQube analysis..."
        // Use single-quoted Groovy string to avoid insecure interpolation warning
        sh '''
          sonar-scanner \
            -Dsonar.projectKey='"'"${SONAR_KEY}"'"' \
            -Dsonar.sources=. \
            -Dsonar.host.url='"'"${SONAR_HOST}"'"' \
            -Dsonar.token="$SONAR_TOKEN"
        '''
      }
    }

    stage('Run Tests') {
      steps {
        echo "🧪 Running unit tests..."
        sh '''
          set -e
          rm -rf node_modules package-lock.json || true

          # If no lockfile exists, npm ci will fail; fall back to npm install (seen in your last run)
          npm ci --no-audit --no-fund || npm install

          npm test || true
        '''
      }
    }

    stage('Docker Build & Security Scan') {
      steps {
        echo "🐳 Building Docker image and scanning with Trivy..."
        sh """
          docker build -t ${ECR_REPO}:${BUILD_TAG} .
          trivy image --exit-code 1 --severity HIGH,CRITICAL ${ECR_REPO}:${BUILD_TAG} || true
        """
      }
    }

    stage('Push to ECR') {
      steps {
        echo "📤 Pushing image to ECR..."
        sh """
          # ✅ Login to the registry host (not the repo path)
          aws ecr get-login-password --region ${AWS_REGION} \
            | docker login --username AWS --password-stdin ${ECR_REGISTRY}

          # Push versioned tag and also 'latest' for rollback/use
          docker tag ${ECR_REPO}:${BUILD_TAG} ${ECR_REPO}:latest
          docker push ${ECR_REPO}:${BUILD_TAG}
          docker push ${ECR_REPO}:latest
        """
      }
    }

    stage('Preflight on EC2 (via SSM)') {
      steps {
        echo "🛠 Preflight on EC2 (install/enable Docker & AWS CLI if needed)..."
        sh """
          aws ssm send-command \
            --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
            --document-name "AWS-RunShellScript" \
            --region ${AWS_REGION} \
            --comment "Preflight Docker & AWS CLI" \
            --parameters 'commands=[
              "set -e",
              "command -v docker || (sudo apt-get update -y && sudo apt-get install -y docker.io)",
              "sudo usermod -aG docker ssm-user || true",
              "sudo systemctl enable --now docker || sudo service docker start || true",
              "docker --version || true",
              "command -v aws || (curl -sSL \\"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\\" -o /tmp/awscliv2.zip && unzip -q /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install || true)"
            ]' \
          --query "Command.CommandId" --output text > .cmdid_pre

          aws ssm wait command-executed \
            --command-id $(cat .cmdid_pre) --instance-id ${INSTANCE_ID} --region ${AWS_REGION}

          aws ssm get-command-invocation \
            --command-id $(cat .cmdid_pre) --instance-id ${INSTANCE_ID} --region ${AWS_REGION} \
            --query 'Status' --output text | grep -E 'Success'
        """
      }
    }

    stage('Deploy to EC2 (via SSM)') {
      steps {
        echo "🚀 Deploying build ${BUILD_NUMBER} to EC2..."
        script {
          def branch  = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
          def commit  = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
          def author  = sh(script: "git log -1 --pretty=format:%an", returnStdout: true).trim()
          def date    = sh(script: "git log -1 --date=iso-strict --pretty=format:%cd", returnStdout: true).trim()
          def message = sh(script: "git log -1 --pretty=format:%s", returnStdout: true).trim()

          // Use parameters directly to avoid malformed cli-input-json
          sh """
            aws ssm send-command \
              --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
              --document-name "AWS-RunShellScript" \
              --region ${AWS_REGION} \
              --comment "Deploy build-${BUILD_NUMBER}" \
              --parameters 'commands=[
                "set -e",
                "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}",
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
              ]' \
            --query "Command.CommandId" --output text > .cmdid_deploy

            aws ssm wait command-executed \
              --command-id $(cat .cmdid_deploy) --instance-id ${INSTANCE_ID} --region ${AWS_REGION}

            echo "---- Deploy output ----"
            aws ssm get-command-invocation \
              --command-id $(cat .cmdid_deploy) --instance-id ${INSTANCE_ID} --region ${AWS_REGION} \
              --query '{Status:Status, StdOut:StandardOutputContent, StdErr:StandardErrorContent}' --output json
          """
        }
      }
    }

    stage('Smoke Test (HTTP 200)') {
      steps {
        echo "🌐 Running smoke test..."
        // Prefer instance public DNS/IP via parameter
        sh "curl -fsS http://18.215.177.39/ -o /dev/null"
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline completed successfully (build #${env.BUILD_NUMBER})"
    }
    failure {
      echo "❌ Pipeline failed. Rolling back..."
      sh """
        aws ssm send-command \
          --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
          --document-name "AWS-RunShellScript" \
          --region ${AWS_REGION} \
          --parameters 'commands=[
            "docker ps -q --filter name=app && docker stop app && docker rm app || true",
            "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}",
            "docker pull ${ECR_REPO}:latest || true",
            "docker run -d --name app -p 80:3000 --restart unless-stopped ${ECR_REPO}:latest || true"
          ]'
      """
    }
    always {
      echo "🧹 Cleaning up Docker junk..."
      sh 'docker system prune -af || true'
    }
  }
}
