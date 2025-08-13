pipeline {
  agent any
  options { timestamps() }

  environment {
    AWS_REGION = 'us-east-1'
    ECR_REGISTRY = '576290270995.dkr.ecr.us-east-1.amazonaws.com'
    ECR_REPO = "${ECR_REGISTRY}/my-node-app"
    IMAGE_TAG = "build-${BUILD_NUMBER}"

    DEPLOY_HOST = '54.90.221.101'                // <-- update if your web EC2 IP changes
    PEM_KEY     = '/var/lib/jenkins/karan.pem'   // <-- path to your SSH key on Jenkins host
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install & Test') {
      steps {
        sh '''
          set -e
          node -v
          npm -v
          # install deps for any local tests/tools
          if [ -f package.json ]; then npm install; fi
          # run tests only if present
          if [ -f test.js ] || [ -d test ]; then
            npm test
          else
            echo "No tests found; skipping."
          fi
        '''
      }
    }

    stage('Docker Build') {
      steps {
        sh '''
          set -e
          # Login to ECR (Jenkins host has IAM role)
          aws ecr get-login-password --region "$AWS_REGION" \
            | docker login --username AWS --password-stdin "$ECR_REGISTRY"

          # Build image (Dockerfile must exist in repo root)
          docker build -t "$ECR_REPO:$IMAGE_TAG" .
        '''
      }
    }

    stage('Push to AWS ECR') {
      steps {
        sh '''
          set -e
          aws ecr get-login-password --region "$AWS_REGION" \
            | docker login --username AWS --password-stdin "$ECR_REGISTRY"
          docker push "$ECR_REPO:$IMAGE_TAG"
        '''
      }
    }

    stage('Deploy to EC2') {
      steps {
        sh '''
          set -e

          # Collect build metadata
          GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD || echo "unknown")
          GIT_COMMIT=$(git rev-parse HEAD || echo "unknown")
          GIT_AUTHOR=$(git log -1 --pretty=format:%an || echo "unknown")
          GIT_MESSAGE=$(git log -1 --pretty=format:%s || echo "unknown")
          GIT_DATE=$(date "+%Y-%m-%d %H:%M:%S")

          # Create env file for container (avoids quoting issues)
          cat > deploy.env <<EOF
BUILD_NUMBER=${BUILD_NUMBER}
GIT_BRANCH=${GIT_BRANCH}
GIT_COMMIT=${GIT_COMMIT}
GIT_AUTHOR=${GIT_AUTHOR}
GIT_MESSAGE=${GIT_MESSAGE}
GIT_DATE=${GIT_DATE}
ENVIRONMENT=PROD
PORT=3000
EOF

          # Get an ECR login token on Jenkins host (no AWS CLI needed on target)
          ECR_PASS=$(aws ecr get-login-password --region "$AWS_REGION")

          # Copy env file to target
          scp -o StrictHostKeyChecking=no -i "$PEM_KEY" deploy.env ubuntu@"$DEPLOY_HOST":/tmp/app.env

          # Remote: login to ECR using the token, pull & (re)start container
          ssh -o StrictHostKeyChecking=no -i "$PEM_KEY" ubuntu@"$DEPLOY_HOST" "
            set -e
            echo '$ECR_PASS' | docker login --username AWS --password-stdin $ECR_REGISTRY
            docker pull $ECR_REPO:$IMAGE_TAG
            (docker stop app || true)
            (docker rm app || true)
            docker run -d --name app --restart unless-stopped \\
              --env-file /tmp/app.env -p 80:3000 $ECR_REPO:$IMAGE_TAG
            # basic health check
            sleep 2
            curl -fsS http://localhost/ >/dev/null && echo 'App is up'
          "
        '''
      }
    }
  }

  post {
    success { echo "✅ Deploy successful: ${env.ECR_REPO}:${env.IMAGE_TAG}" }
    failure { echo "❌ Pipeline failed" }
    always  {
      sh 'docker system prune -af || true'
    }
  }
}
