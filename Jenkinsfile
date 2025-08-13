pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO_URI = '576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app'
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
                    dockerImage = docker.build("${ECR_REPO_URI}:latest")
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                script {
                    withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} \
                            | docker login --username AWS --password-stdin ${ECR_REPO_URI}
                        """
                        dockerImage.push('latest')
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploy step here (SSH to EC2 or ECS task update)"
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
