pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1" // change if needed
        ECR_REPO = "your-ecr-repo-name" // change to your repo
        IMAGE_TAG = "latest"
        AWS_CREDENTIALS = credentials('aws-creds')
        EC2_HOST = "ec2-user@your-ec2-public-ip" // change to your EC2 IP
        PEM_KEY_PATH = "/var/lib/jenkins/your-key.pem" // update if needed
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    dockerImage = docker.build("${ECR_REPO}:${IMAGE_TAG}")
                }
            }
        }

        stage('Docker Push to ECR') {
            steps {
                script {
                    sh """
                        aws configure set aws_access_key_id ${AWS_CREDENTIALS_USR}
                        aws configure set aws_secret_access_key ${AWS_CREDENTIALS_PSW}
                        aws configure set default.region ${AWS_REGION}

                        AWS_ACCOUNT_ID=\$(aws sts get-caller-identity --query Account --output text)
                        ECR_URI=\${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}

                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin \${ECR_URI}
                        docker tag ${ECR_REPO}:${IMAGE_TAG} \${ECR_URI}:${IMAGE_TAG}
                        docker push \${ECR_URI}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sh """
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ${EC2_HOST} '
                            docker pull \$(aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} --query "repositories[0].repositoryUri" --output text):${IMAGE_TAG} &&
                            docker stop node-app || true &&
                            docker rm node-app || true &&
                            docker run -d --name node-app -p 80:3000 \$(aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} --query "repositories[0].repositoryUri" --output text):${IMAGE_TAG}
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful!"
        }
        failure {
            echo "❌ Deployment failed!"
        }
    }
}
