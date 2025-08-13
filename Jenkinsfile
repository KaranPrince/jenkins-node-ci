pipeline {
  agent any
  options { timestamps() }

  environment {
    AWS_REGION   = 'us-east-1'
    ECR_REGISTRY = '576290270995.dkr.ecr.us-east-1.amazonaws.com'
    ECR_REPO     = "${ECR_REGISTRY}/my-node-app"
    EC2_HOST     = '54.90.221.101'
    SSH_KEY      = '/var/lib/jenkins/karan.pem'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Prepare & Tests') {
      steps {
        sh '''
          set -e
          echo "[jenkins] node & npm versions"
          node -v || true
          npm -v  || true

          # install dev deps only if package.json exists (useful for local tests)
          if [ -f package.json ]; then
            echo "[jenkins] npm install (for tests only)"
            npm ci || npm install
          fi

          # (optional) run tests if present
          if npm run | grep -q "test"; then
            if [ -f test.js ] || [ -d test ]; then
              echo "[jenkins] running tests"
              npm test || (echo "Tests failed"; exit 1)
            else
              echo "[jenkins] no tests found"
            fi
          fi
        '''
      }
    }

    stage('Build & Push Image to ECR') {
      steps {
        sh '''
          set -e
          IMAGE_TAG=build-$BUILD_NUMBER

          echo "[jenkins] ensure we can login to ECR from Jenkins host (IAM role or creds)"
          aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

          echo "[jenkins] building docker image: $ECR_REPO:$IMAGE_TAG"
          DOCKER_BUILDKIT=1 docker build -t "$ECR_REPO:$IMAGE_TAG" .

          echo "[jenkins] tag latest and push"
          docker tag "$ECR_REPO:$IMAGE_TAG" "$ECR_REPO:latest"
          docker push "$ECR_REPO:$IMAGE_TAG"
          docker push "$ECR_REPO:latest"
        '''
      }
    }

    stage('Deploy to EC2') {
      steps {
        sh '''
          set -e
          IMAGE_TAG=build-$BUILD_NUMBER

          # gather git/build metadata (written to env-file for container)
          GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD || echo unknown)
          GIT_COMMIT=$(git rev-parse HEAD || echo unknown)
          GIT_AUTHOR=$(git log -1 --pretty=format:%an || echo unknown)
          GIT_MESSAGE=$(git log -1 --pretty=format:%s || echo unknown)
          GIT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

          cat > deploy.env <<EOF
BUILD_NUMBER=$BUILD_NUMBER
GIT_BRANCH=$GIT_BRANCH
GIT_COMMIT=$GIT_COMMIT
GIT_AUTHOR=$GIT_AUTHOR
GIT_MESSAGE=$GIT_MESSAGE
GIT_DATE=$GIT_DATE
ENVIRONMENT=PROD
PORT=3000
EOF

          # create a short-lived ECR token file and copy both files to remote
          ECR_TOKEN_FILE="/tmp/ecr_token_$BUILD_NUMBER.txt"
          aws ecr get-login-password --region "$AWS_REGION" > "$ECR_TOKEN_FILE"
          scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "$ECR_TOKEN_FILE" ubuntu@"$EC2_HOST":/tmp/ecr_token.txt
          scp -o StrictHostKeyChecking=no -i "$SSH_KEY" deploy.env ubuntu@"$EC2_HOST":/tmp/app.env
          rm -f "$ECR_TOKEN_FILE"
          rm -f deploy.env

          # remote commands: login, free port 80, pull image, run container with env-file
          ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$EC2_HOST" "
            set -e

            ECR_REGISTRY='$ECR_REGISTRY'
            ECR_REPO='$ECR_REPO'
            IMAGE_TAG='$IMAGE_TAG'

            # ensure docker installed
            if ! command -v docker >/dev/null 2>&1; then
              echo '[remote] docker not found, installing docker...'
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl enable --now docker
            fi

            # login using the token file copied from Jenkins
            cat /tmp/ecr_token.txt | docker login --username AWS --password-stdin \"$ECR_REGISTRY\" || (echo '[remote] docker login failed' && exit 1)
            rm -f /tmp/ecr_token.txt

            echo '[remote] stopping web servers that may hold port 80'
            sudo systemctl stop nginx || true
            sudo systemctl stop apache2 || true
            sudo fuser -k 80/tcp || true

            echo '[remote] pulling image' 
            docker pull \"$ECR_REPO:$IMAGE_TAG\"

            echo '[remote] removing old container (if exists)'
            docker rm -f app || true

            echo '[remote] starting new container'
            docker run -d --name app --restart unless-stopped --env-file /tmp/app.env -p 80:3000 \"$ECR_REPO:$IMAGE_TAG\"

            # basic health check
            sleep 3
            if curl -fsS http://localhost/ >/dev/null; then
              echo '[remote] healthcheck succeeded'
            else
              echo '[remote] healthcheck failed' >&2
              exit 1
            fi
          "
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline succeeded - image pushed & deployed"
    }
    failure {
      echo "❌ Pipeline failed - check logs above"
    }
    always {
      sh 'docker system prune -af || true'
    }
  }
}
