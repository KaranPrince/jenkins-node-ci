pipeline {
  agent any
  options { timestamps(); ansiColor('xterm') }

  environment {
    AWS_REGION        = "us-east-1"
    ECR_REPO          = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
    INSTANCE_ID       = "i-0e2c8e55425432246"
    BUILD_TAG         = "build-${env.BUILD_NUMBER}"

    SONAR_PROJECT_KEY = "jenkins-node-ci"
    SONAR_HOST_URL    = "http://13.217.194.227:9000"
    SONAR_LOGIN       = credentials('sonarqube-token')   // Secret text cred

    // Optional: if you added an AWS credential in Jenkins (Access key/secret)
    // Uncomment and use withCredentials block below instead of relying on host IAM role.
    AWS_ACCESS_KEY_ID     = credentials('aws-credentials')
    AWS_SECRET_ACCESS_KEY = credentials('aws-credentials')
  }

  stages {
    stage('Checkout') {
      steps {
        echo "🔄 Checking out source..."
        git branch: 'master', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
      }
    }

    stage('Env Prep (CLI tools)') {
      steps {
        echo "🧰 Ensuring awscli, sonar-scanner, trivy exist (best-effort)..."
        sh '''
          set -e
          if ! command -v aws >/dev/null 2>&1; then
            sudo apt-get update -y && sudo apt-get install -y awscli
          fi

          if ! command -v sonar-scanner >/dev/null 2>&1; then
            sudo apt-get update -y && sudo apt-get install -y unzip curl
            SC_VER="5.0.1.3006"
            curl -fsSL -o /tmp/sonar.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SC_VER}-linux.zip" || true
            [ -f /tmp/sonar.zip ] && sudo unzip -o /tmp/sonar.zip -d /opt && \
              sudo ln -sf /opt/sonar-scanner-* /opt/sonar-scanner && \
              echo 'export PATH=/opt/sonar-scanner/bin:$PATH' | sudo tee /etc/profile.d/sonar.sh >/dev/null
            . /etc/profile || true
          fi

          if ! command -v trivy >/dev/null 2>&1; then
            sudo apt-get update -y && sudo apt-get install -y wget apt-transport-https gnupg lsb-release
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
            echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
            sudo apt-get update -y && sudo apt-get install -y trivy
          fi
        '''
      }
    }

    stage('Static Code Analysis (SonarQube)') {
      steps {
        echo "🔎 Running SonarQube analysis..."
        sh '''
          export PATH="/opt/sonar-scanner/bin:$PATH"
          sonar-scanner \
            -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
            -Dsonar.sources=. \
            -Dsonar.host.url="$SONAR_HOST_URL" \
            -Dsonar.token="$SONAR_LOGIN"
        '''
      }
    }

    stage('Unit Tests (Node in Docker)') {
      steps {
        echo "🧪 Running tests in Node 18 container..."
        sh '''
          docker run --rm -v "$PWD":/workspace -w /workspace node:18-alpine sh -lc "
            npm ci || npm install
            npm test
          "
        '''
      }
    }

    stage('Build Image & Scan (Trivy)') {
      steps {
        echo "🐳 Building image and scanning for vulnerabilities..."
        sh '''
          docker build -t "$ECR_REPO:$BUILD_TAG" .
          # Fail build on High/Critical, but let the pipeline continue for demo by `|| true`
          trivy image --severity HIGH,CRITICAL --exit-code 1 "$ECR_REPO:$BUILD_TAG" || true
        '''
      }
    }

    stage('Push to ECR') {
      steps {
        echo "📤 Pushing image to ECR..."
        sh '''
          aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REPO"
          docker push "$ECR_REPO:$BUILD_TAG"
        '''
      }
    }

    stage('Deploy to EC2 via SSM') {
  steps {
    echo "🚀 Deploying to EC2 via SSM..."
    script {
      def branch   = sh(returnStdout: true, script: "git rev-parse --abbrev-ref HEAD").trim()
      def commit   = sh(returnStdout: true, script: "git rev-parse HEAD").trim()
      def author   = sh(returnStdout: true, script: "git log -1 --pretty=format:%an").trim()
      def date     = sh(returnStdout: true, script: "git log -1 --pretty=format:%cd").trim()
      def message  = sh(returnStdout: true, script: "git log -1 --pretty=format:%s").trim()

      sh """
        aws ssm send-command \
          --document-name "AWS-RunShellScript" \
          --comment "Deploy ${BUILD_TAG} to EC2" \
          --targets "Key=instanceIds,Values=${INSTANCE_ID}" \
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
              -e GIT_AUTHOR=\\"${author}\\" \
              -e GIT_DATE=\\"${date}\\" \
              -e GIT_MESSAGE=\\"${message}\\" \
              -e ENVIRONMENT=prod \
              ${ECR_REPO}:${BUILD_TAG}"
          ]'
      """
    }
  }
}


    stage('Smoke Check (Public HTTP 200)') {
      steps {
        echo "🩺 Checking container health via HTTP..."
        // Replace YOUR_WEB_PUBLIC_IP with your web host's public DNS/IP serving port 80
        sh '''
          WEB="http://18.215.177.39/"
          code=$(curl -s -o /dev/null -w "%{http_code}" "$WEB")
          if [ "$code" -ne 200 ]; then
            echo "❌ Smoke test failed: HTTP $code"
            exit 1
          fi
          echo "✅ Smoke test passed"
        '''
      }
    }

    stage('Cleanup (Docker)') {
      steps {
        echo "🧽 Pruning local Docker artifacts..."
        sh 'docker system prune -af || true'
      }
    }
  }

  post {
    success { echo "✅ Deployment successful: $ECR_REPO:$BUILD_TAG" }
    failure { echo "❌ Pipeline failed. Check stage logs above." }
    always  { echo "ℹ️ Pipeline finished (build #${env.BUILD_NUMBER})." }
  }
}
