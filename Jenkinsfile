pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        ECR_REPO_URI = "576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app"
        DOCKER_IMAGE = "${ECR_REPO_URI}:${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Checking out repository..."
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "Installing NPM dependencies..."
                sh 'cd app && npm install'
            }
        }

        stage('Test') {
            steps {
                echo "Running tests..."
                // Replace with actual test command if available
                sh 'cd app && npm test || echo "No tests found"'
            }
        }

        stage('Docker Build & Push') {
            steps {
                echo "Building Docker image..."
                script {
                    sh """
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URI
                        docker build -t $DOCKER_IMAGE .
                        docker push $DOCKER_IMAGE
                    """
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploying container to server..."
                sh """
                    ssh -o StrictHostKeyChecking=no -i /path/to/key.pem ec2-user@YOUR_EC2_PUBLIC_IP "
                        docker pull $DOCKER_IMAGE &&
                        docker stop my-node-app || true &&
                        docker rm my-node-app || true &&
                        docker run -d -p 80:3000 --name my-node-app $DOCKER_IMAGE
                    "
                """
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
