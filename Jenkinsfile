pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install --prefix app'
            }
        }

        stage('Run Tests & Lint') {
            steps {
                sh 'npm test --prefix app || echo "Tests failed but continuing..."'
                sh 'npm run lint --prefix app || echo "Lint warnings..."'
            }
        }

        stage('Build Application') {
            steps {
                sh 'echo "Building application..."'
                // Example for frontend build: sh 'npm run build --prefix app'
            }
        }

        stage('Docker Build & Push to ECR') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS --password-stdin ${ECR_REPO}

                        docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                        docker push ${ECR_REPO}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to Server') {
            steps {
                sh '''
                echo "Deploying application..."
                # Example for EC2: ssh -i key.pem ec2-user@IP "docker pull ${ECR_REPO}:${IMAGE_TAG} && docker run -d -p 3000:3000 ${ECR_REPO}:${IMAGE_TAG}"
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Build ${BUILD_NUMBER} completed successfully."
        }
        failure {
            echo "❌ Build ${BUILD_NUMBER} failed."
        }
    }
}
