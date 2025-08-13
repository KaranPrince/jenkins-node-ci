pipeline {
  agent any

  options {
    ansiColor('xterm')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20', daysToKeepStr: '14'))
    timestamps()
  }

  environment {
    // ---- Project / App ----
    APP_PORT       = '3000'
    CONTAINER_NAME = 'jenkins_app'

    // ---- AWS / ECR ----
    AWS_REGION     = 'us-east-1'                 // <--- change if needed
    ECR_REPO       = 'jenkins-node-ci'           // <--- your ECR repo name (will be created if missing)

    // ---- EC2 ----
    EC2_USER       = 'ubuntu'
    EC2_HOST       = '54.90.221.101'             // <--- update if IP changes (or use Elastic IP!)
    PEM_KEY_PATH   = '/var/lib/jenkins/karan.pem'
  }

  stages {
    stage('Checkout') {
      steps {
        echo '📥 Checking out source...'
        cleanWs()
        checkout scm
      }
    }

    stage('Install Dependencies') {
      steps {
        echo '📦 Installing dependencies...'
        // prefer npm ci if you use package-lock.json
        sh 'if [ -f package-lock.json ]; then npm ci; else npm install; fi'
      }
    }

    stage('Unit Tests') {
      steps {
        echo '🧪 Running tests...'
        // your package.json already has: "test": "mocha test.js"
        sh 'npm test'
      }
    }

    stage('Inject Build & Git Metadata') {
      steps {
        echo '📝 Injecting build metadata into app/index.html...'
        script {
          // collect git info
          def branch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
          def commit = sh(script: "git rev-parse HEAD",               returnStdout: true).trim()
          def author = sh(script: "git log -1 --pretty=format:%an",   returnStdout: true).trim()
          def msg    = sh(script: "git log -1 --pretty=format:%s",    returnStdout: true).trim()
          def now    = sh(script: "date '+%Y-%m-%d %H:%M:%S'",        returnStdout: true).trim()

          // do all replacements within a single shell block (safe quoting)
          sh '''
            set -e
            f="app/index.html"
            [ -f "$f" ] || { echo "index.html not found at $f" ; exit 1; }
            # Use shell env variables (provided by Jenkins) safely here
            sed -i "s|__BUILD_NUMBER__|$BUILD_NUMBER|g" "$f"
            sed -i "s|__GIT_BRANCH__|'${branch}'|g"     "$f"
            sed -i "s|__GIT_COMMIT__|'${commit}'|g"     "$f"
            sed -i "s|__GIT_AUTHOR__|'${author}'|g"     "$f"
            sed -i "s|__GIT_DATE__|'${now}'|g"          "$f"
            sed -i "s|__GIT_MESSAGE__|'${msg}'|g"       "$f"
          '''
        }
      }
    }

    stage('Docker Build (local)') {
      steps {
        echo '🐳 Building Docker image locally...'
        // Tag locally with simple name; we’ll retag for ECR later
        sh '''
          set -e
          docker build --pull -t local/jenkins-node-ci:latest .
        '''
      }
    }

    stage('Push Image to AWS ECR') {
      environment {
        // Jenkins credential: "AWS Credentials" from the AWS Credentials plugin
        // Make sure you created an entry with ID: "aws-jenkins-cred"
        // It will export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY for this block
      }
      steps {
        echo '📤 Pushing image to AWS ECR...'
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                          credentialsId: 'aws-jenkins-cred',
                          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sh '''
            set -e
            # Discover AWS Account ID dynamically
            AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

            # Ensure repo exists (idempotent)
            aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$AWS_REGION" >/dev/null 2>&1 \
              || aws ecr create-repository --repository-name "$ECR_REPO" --region "$AWS_REGION" >/dev/null

            # Login to ECR
            aws ecr get-login-password --region "$AWS_REGION" \
              | docker login --username AWS --password-stdin "$ECR_REGISTRY"

            # Tag & push (latest + build number)
            docker tag local/jenkins-node-ci:latest "$ECR_REGISTRY/$ECR_REPO:latest"
            docker tag local/jenkins-node-ci:latest "$ECR_REGISTRY/$ECR_REPO:$BUILD_NUMBER"

            docker push "$ECR_REGISTRY/$ECR_REPO:$BUILD_NUMBER"
            docker push "$ECR_REGISTRY/$ECR_REPO:latest"
          '''
        }
      }
    }

    stage('Deploy to EC2 (Docker)') {
      steps {
        echo '🚀 Deploying container on EC2 from ECR...'
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                          credentialsId: 'aws-jenkins-cred',
                          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sh '''
            set -e

            AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
            IMAGE="$ECR_REGISTRY/$ECR_REPO:latest"

            ssh -i "$PEM_KEY_PATH" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_HOST" '
              set -e
              # Install AWS CLI v2 if missing (lightweight, idempotent)
              if ! command -v aws >/dev/null 2>&1; then
                sudo apt-get update -y
                sudo apt-get install -y unzip curl
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip -q awscliv2.zip
                sudo ./aws/install
                rm -rf aws awscliv2.zip
              fi

              # ECR login on the instance
              AWS_ACCOUNT_ID=$('"$AWS_ACCOUNT_ID"')
              AWS_REGION='"$AWS_REGION"'
              ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
              sudo aws ecr get-login-password --region "$AWS_REGION" | sudo docker login --username AWS --password-stdin "$ECR_REGISTRY"

              # Pull & (re)run
              sudo docker pull '"$IMAGE"'
              sudo docker stop '"$CONTAINER_NAME"' || true
              sudo docker rm   '"$CONTAINER_NAME"' || true
              sudo docker run -d --name '"$CONTAINER_NAME"' -p 80:'"$APP_PORT"' '"$IMAGE"'
            '
          '''
        }
      }
    }

    stage('Health Check') {
      steps {
        echo '🩺 Verifying deployment...'
        sh '''
          set -e
          # simple HTTP check
          code=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_HOST/")
          if [ "$code" -ne 200 ]; then
            echo "Health check failed with HTTP $code"
            exit 1
          fi
          echo "Health check OK (HTTP $code)"
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline OK — deployed build #${env.BUILD_NUMBER} to ${env.EC2_HOST}"
    }
    failure {
      echo "❌ Pipeline FAILED — investigate logs above."
    }
  }
}
