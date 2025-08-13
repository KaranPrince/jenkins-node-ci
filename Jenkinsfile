pipeline {
  agent any

  environment {
    AWS_REGION = "us-east-1"
    ECR_REPO  = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
    IMAGE_TAG = "build-${BUILD_NUMBER}"

    // EC2 deploy target
    EC2_USER = "ubuntu"
    EC2_HOST = "54.90.221.101"                // <-- update if IP changes
    SSH_KEY  = "/var/lib/jenkins/karan.pem"   // <-- your key path
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          set -e
          aws ecr get-login-password --region "$AWS_REGION" \
            | docker login --username AWS --password-stdin "$ECR_REPO"

          DOCKER_BUILDKIT=1 docker build -t "$ECR_REPO:$IMAGE_TAG" .
        '''
      }
    }

    stage('Push to AWS ECR') {
      steps {
        sh '''
          set -e
          aws ecr get-login-password --region "$AWS_REGION" \
            | docker login --username AWS --password-stdin "$ECR_REPO"

          docker push "$ECR_REPO:$IMAGE_TAG"
        '''
      }
    }

    stage('Deploy to EC2') {
      steps {
        sh '''
          set -e
          # Get one-time ECR token on Jenkins, pass it to the remote host for docker login
          ECR_PASS="$(aws ecr get-login-password --region "$AWS_REGION")"

          ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$EC2_USER@$EC2_HOST" bash -s <<EOF
set -e

# ensure curl exists for healthcheck
if ! command -v curl >/dev/null 2>&1; then
  sudo apt-get update -y && sudo apt-get install -y curl
fi

# docker login on remote
printf '%s' "$ECR_PASS" | docker login --username AWS --password-stdin "$ECR_REPO" >/dev/null
echo "[remote] docker login ok"

# free port 80 (stop nginx/apache or any process)
sudo systemctl stop nginx || true
sudo systemctl stop apache2 || true
sudo fuser -k 80/tcp || true

# pull and (re)run the app
docker pull "$ECR_REPO:$IMAGE_TAG"
docker rm -f app || true
docker run -d --name app --restart unless-stopped -p 80:3000 "$ECR_REPO:$IMAGE_TAG"

# basic health check
sleep 2
curl -fsS http://localhost/ >/dev/null && echo "[remote] App is up"
EOF
        '''
      }
    }
  }

  post {
    success { echo '✅ Pipeline OK' }
    failure { echo '❌ Pipeline failed' }
    always  { sh 'docker system prune -af || true' }
  }
}
