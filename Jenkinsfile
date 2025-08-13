pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        ECR_REPO = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        DEPLOY_HOST = "54.90.221.101"
        PEM_KEY = "/var/lib/jenkins/karan.pem"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                        docker build -t $ECR_REPO:$IMAGE_TAG .
                    """
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                        docker push $ECR_REPO:$IMAGE_TAG
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sh """
                        ssh -o StrictHostKeyChecking=no -i $PEM_KEY ubuntu@$DEPLOY_HOST '
                            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO &&
                            docker pull $ECR_REPO:$IMAGE_TAG &&
                            (docker stop app || true) &&
                            (docker rm app || true) &&
                            docker run -d --name app -p 80:3000 $ECR_REPO:$IMAGE_TAG
                        '
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up local Docker images..."
            sh 'docker system prune -af || true'
        }
    }
}
