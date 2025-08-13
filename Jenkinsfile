pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "karan-node-app"
        DOCKER_TAG = "latest"
        CONTAINER_NAME = "node-app-container"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Installing dependencies...'
                sh 'npm install'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                // If you don't have tests yet, skip with a message
                sh 'echo "No tests found, skipping test stage"'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Building and running Docker container...'
                sh """
                    docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                    docker run -d --name ${CONTAINER_NAME} -p 3000:3000 ${DOCKER_IMAGE}:${DOCKER_TAG}
                """
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished!'
        }
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Deployment failed!'
        }
    }
}
