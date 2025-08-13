pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        ECR_REPO = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
        INSTANCE_ID = "i-0e5abeaed34efdcc2" // Replace with your EC2 Instance ID
        BUILD_TAG = "build-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
            }
        }

        stage('Docker Build & Push to ECR') {
            steps {
                script {
                    sh '''
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                    docker build -t $ECR_REPO:$BUILD_TAG .
                    docker push $ECR_REPO:$BUILD_TAG
                    '''
                }
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                script {
                    sh '''
                    aws ssm send-command \
                        --targets "Key=instanceIds,Values=$INSTANCE_ID" \
                        --comment "Deploy latest container" \
                        --document-name "AWS-RunShellScript" \
                        --region $AWS_REGION \
                        --parameters 'commands=[
                          "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO",
                          "docker pull $ECR_REPO:$BUILD_TAG",
                          "docker stop app || true",
                          "docker rm app || true",
                          "docker run -d --name app -p 80:3000 $ECR_REPO:$BUILD_TAG"
                        ]'
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -af || true'
        }
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}
