pipeline {
  agent any

  environment {
    AWS_REGION        = "us-east-1"
    ECR_REPO          = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
    INSTANCE_ID       = "i-0e2c8e55425432246"
    BUILD_TAG         = "build-${env.BUILD_NUMBER}"
    SONAR_PROJECT_KEY = "jenkins-node-ci"
    SONAR_HOST_URL    = "http://52.91.159.201:9000"
    // Make sure this ID exists in Jenkins (see section B)
    SONAR_LOGIN       = credentials('sonarqube-token')
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'master', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        sh """
          sonar-scanner \
            -Dsonar.projectKey=$SONAR_PROJECT_KEY \
            -Dsonar.sources=. \
            -Dsonar.host.url=$SONAR_HOST_URL \
            -Dsonar.token=$SONAR_LOGIN
        """
      }
    }

    stage('Run Tests') {
      steps {
        sh 'npm install && npm test'
      }
    }

    stage('Docker Build & Vulnerability Scan') {
      steps {
        sh """
          docker build -t $ECR_REPO:$BUILD_TAG .
          trivy image --exit-code 1 $ECR_REPO:$BUILD_TAG || true
        """
      }
    }

    stage('Push to ECR') {
      steps {
        sh '''
          aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
          docker push $ECR_REPO:$BUILD_TAG
        '''
      }
    }

    stage('Deploy to EC2 via SSM') {
      steps {
        sh '''
          aws ssm send-command \
            --targets "Key=instanceIds,Values='$INSTANCE_ID'" \
            --comment "Deploy latest container" \
            --document-name "AWS-RunShellScript" \
            --region $AWS_REGION \
            --parameters 'commands=[
              "aws ecr get-login-password --region '$AWS_REGION' | docker login --username AWS --password-stdin '$ECR_REPO'",
              "docker pull '$ECR_REPO':'$BUILD_TAG'",
              "docker stop app || true",
              "docker rm app || true",
              "docker run -d --name app -p 80:3000 '$ECR_REPO':'$BUILD_TAG'"
            ]'
        '''
      }
    }

    // NEW: run cleanup as a normal stage so it has node/workspace context
    stage('Cleanup') {
      steps {
        sh 'docker system prune -af || true'
      }
    }
  }

  post {
    success { echo "✅ Deployment successful!" }
    failure { echo "❌ Deployment failed!" }
  }
}

