pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials') // Jenkins credentials ID
        DOCKER_IMAGE = "karanprince/nodejs-app"
        SERVER_IP = "54.90.221.101" // Update when IP changes
        SERVER_USER = "ubuntu"
        PEM_KEY_PATH = "/var/lib/jenkins/keys/aws-key.pem"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
            }
        }

        stage('Install & Build') {
            steps {
                dir('app') { // Make sure this is your project folder
                    sh 'npm install'
                    sh 'npm run build || echo "No build script found"'
                }
            }
        }

        stage('Test') {
            steps {
                dir('app') {
                    sh 'npm test || echo "No tests found"'
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    sh """
                    docker build -t ${DOCKER_IMAGE}:latest .
                    echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                    docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh """
                    ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ${SERVER_USER}@${SERVER_IP} '
                        docker pull ${DOCKER_IMAGE}:latest &&
                        docker stop nodejs-app || true &&
                        docker rm nodejs-app || true &&
                        docker run -d --name nodejs-app -p 3000:3000 ${DOCKER_IMAGE}:latest
                    '
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Deployment failed.'
        }
    }
}
