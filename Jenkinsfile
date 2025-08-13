pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        ECR_REPO = "123456789012.dkr.ecr.us-east-1.amazonaws.com/your-repo"
        EC2_HOST = "54.90.221.101"
        EC2_USER = "ubuntu"
        PEM_KEY = "/var/lib/jenkins/karan.pem"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${ECR_REPO}:latest")
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                        docker push $ECR_REPO:latest
                    """
                }
            }
        }

        stage('Prepare ECR Token') {
            steps {
                script {
                    sh """
                        ECR_TOKEN_FILE=/tmp/ecr_token_\$(date +%s).txt
                        aws ecr get-login-password --region $AWS_REGION > \$ECR_TOKEN_FILE
                        chmod 600 \$ECR_TOKEN_FILE

                        echo "Checking SSH connectivity..."
                        timeout 10s bash -c "cat < /dev/null > /dev/tcp/$EC2_HOST/22" || {
                            echo "ERROR: SSH to $EC2_HOST on port 22 is not reachable."
                            exit 1
                        }

                        echo "Copying token file to EC2..."
                        scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $PEM_KEY \$ECR_TOKEN_FILE $EC2_USER@$EC2_HOST:/tmp/ecr_token.txt
                    """
                }
            }
        }

        stage('Deploy on EC2') {
            steps {
                script {
                    sh """
                        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $PEM_KEY $EC2_USER@$EC2_HOST '
                            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO &&
                            docker pull $ECR_REPO:latest &&
                            docker stop myapp || true &&
                            docker rm myapp || true &&
                            docker run -d --name myapp -p 80:3000 $ECR_REPO:latest
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
    }
}
