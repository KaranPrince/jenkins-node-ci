pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "Checking out repository..."
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "Installing Node.js dependencies..."
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                echo "Running tests..."
                sh 'echo "No tests configured yet"'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo "Logging in to AWS ECR..."
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh """
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set default.region ${AWS_REGION}
                        aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_REPO}
                    """
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                echo "Pushing image to AWS ECR..."
                sh "docker push ${ECR_REPO}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "Deploying to EC2..."
                sh """
                ssh -o StrictHostKeyChecking=no -i /path/to/key.pem ec2-user@your-ec2-ip \
                'docker pull ${ECR_REPO}:${IMAGE_TAG} && docker stop app || true && docker rm app || true && docker run -d --name app -p 80:3000 ${ECR_REPO}:${IMAGE_TAG}'
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully ✅"
        }
        failure {
            echo "Pipeline failed ❌"
        }
    }
}
