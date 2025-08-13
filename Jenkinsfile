pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        ECR_REPO = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
        ECR_TAG = "latest"
        EC2_PRIVATE_IP = "10.0.1.192" // Web server private IP
        PEM_KEY = "/var/lib/jenkins/karan.pem"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin $ECR_REPO
                        DOCKER_BUILDKIT=1 docker build -t $ECR_REPO:$ECR_TAG .
                    """
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                sh "docker push $ECR_REPO:$ECR_TAG"
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    // Copy ECR login token to EC2
                    sh """
                        aws ecr get-login-password --region $AWS_REGION > /tmp/ecr_token.txt
                        scp -o StrictHostKeyChecking=no -i $PEM_KEY /tmp/ecr_token.txt ubuntu@$EC2_PRIVATE_IP:/tmp/ecr_token.txt
                    """

                    // SSH into EC2 and run container
                    sh """
                        ssh -o StrictHostKeyChecking=no -i $PEM_KEY ubuntu@$EC2_PRIVATE_IP '
                        cat /tmp/ecr_token.txt | docker login --username AWS --password-stdin $ECR_REPO &&
                        docker pull $ECR_REPO:$ECR_TAG &&
                        docker stop app || true &&
                        docker rm app || true &&
                        docker run -d --name app -p 80:3000 $ECR_REPO:$ECR_TAG
                        '
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -af || true'
        }
        failure {
            echo "❌ Pipeline failed"
        }
        success {
            echo "✅ Deployment successful"
        }
    }
}
