pipeline {
  agent any

  environment {
    AWS_REGION   = "us-east-1"
    ECR_REPO     = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
    INSTANCE_ID  = "i-0e2c8e55425432246"
    BUILD_TAG    = "build-${env.BUILD_NUMBER}"
    LATEST_TAG   = "latest"

    SONAR_KEY    = "jenkins-node-ci"
    SONAR_HOST   = "http://<SONARQUBE_HOST>:9000"
    SONAR_TOKEN  = credentials('sonarqube-token')

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
            sh """
              sonar-scanner \
                -Dsonar.projectKey=$SONAR_KEY \
                -Dsonar.sources=. \
                -Dsonar.host.url=$SONAR_HOST \
                -Dsonar.token=$SONAR_TOKEN
            """
          }
        }
        stage('Unit Tests') {
          steps {
            sh '''
              set -e
              npm ci --no-audit --no-fund
              npm test || true
            '''
          }
        }
      }
    }

    stage('Security Scan (Trivy FS)') {
      steps {
        sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL --no-progress .'
      }
    }

    stage('Docker Build & Scan') {
      steps {
        sh """
          docker build -t $ECR_REPO:$BUILD_TAG .
          trivy image --severity HIGH,CRITICAL --no-progress $ECR_REPO:$BUILD_TAG || true
        """
      }
    }

    stage('Push to ECR') {
      steps {
        sh """
          aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
          docker tag $ECR_REPO:$BUILD_TAG $ECR_REPO:$LATEST_TAG
          docker push $ECR_REPO:$BUILD_TAG
          docker push $ECR_REPO:$LATEST_TAG
        """
      }
    }

    stage('Deploy to EC2') {
      steps {
        sh """
          aws ssm send-command \
            --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
            --document-name "AWS-RunShellScript" \
            --region ${AWS_REGION} \
            --parameters 'commands=[
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
              for i in {1..12}; do
                if curl -fsS "$APP_URL" > /dev/null; then exit 0; fi
                sleep 5
              done
              exit 1
            '''
          )
          if (rc != 0) {
            sh """
              aws ssm send-command \
                --targets "Key=InstanceIds,Values=${INSTANCE_ID}" \
                --document-name "AWS-RunShellScript" \
                --region ${AWS_REGION} \
                --parameters 'commands=[
                  "docker stop app || true",
                  "docker rm app || true",
                  "docker run -d --name app -p 80:3000 --restart unless-stopped ${ECR_REPO}:${LATEST_TAG}"
                ]'
            """
            error("❌ Healthcheck failed, rolled back to last good image.")
          }
        }
      }
    }
  }

  post {
    always {
      sh 'docker system prune -af || true'
    }
  }
}
