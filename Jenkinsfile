pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        AWS_ACCOUNT_ID = "576290270995"
        ECR_REPO_NAME = "my-node-app"
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        EC2_USER = "ubuntu"
        EC2_HOST = "54.90.221.101"
        PEM_KEY = "/var/lib/jenkins/karan.pem"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "Checking out repository..."
                git branch: 'main', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
            }
        }

        stage('AWS ECR Login Token') {
            steps {
                script {
                    def GIT_DATE = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
                    def ECR_TOKEN_FILE = "/tmp/ecr_token_${BUILD_NUMBER}.txt"

                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} > ${ECR_TOKEN_FILE}
                        scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ${PEM_KEY} ${ECR_TOKEN_FILE} ${EC2_USER}@${EC2_HOST}:/tmp/ecr_token.txt || exit 1
                    """
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        DOCKER_BUILDKIT=1 docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG} -f Dockerfile .
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to EC2') {
    steps {
        echo "Deploying to EC2 instance..."
        script {
            def EC2_PRIVATE_IP = "10.0.1.192" // Web server private IP

            // Generate and copy ECR login token to target server
            sh """
                set -e
                ECR_TOKEN_FILE=/tmp/ecr_token.txt
                aws ecr get-login-password --region us-east-1 > \$ECR_TOKEN_FILE
                scp -o StrictHostKeyChecking=no -i /var/lib/jenkins/karan.pem \$ECR_TOKEN_FILE ubuntu@${EC2_PRIVATE_IP}:/tmp/ecr_token.txt
            """

            // SSH into server and pull + run the container
            sh """
                ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/karan.pem ubuntu@${EC2_PRIVATE_IP} '
                cat /tmp/ecr_token.txt | docker login --username AWS --password-stdin 576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app &&
                docker pull 576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app:latest &&
                docker stop app || true &&
                docker rm app || true &&
                docker run -d --name app -p 80:3000 576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app:latest
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
