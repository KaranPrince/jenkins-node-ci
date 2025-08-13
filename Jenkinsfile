pipeline {
    agent any

    environment {
        APP_NAME = "jenkins-node-ci"
        DOCKER_IMAGE = "karanprince/${APP_NAME}"
        WEB_SERVER_USER = "ubuntu"
        WEB_SERVER_IP = "54.90.221.101" // ✅ UPDATE when EC2 IP changes
        PEM_KEY_PATH = "/var/lib/jenkins/karan.pem"
        DEPLOY_PATH = "/var/www/html/${APP_NAME}"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:latest ."
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-cred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to Web Server') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                        ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${WEB_SERVER_USER}@${WEB_SERVER_IP} '
                            sudo mkdir -p ${DEPLOY_PATH} &&
                            sudo docker rm -f ${APP_NAME} || true &&
                            sudo docker pull ${DOCKER_IMAGE}:latest &&
                            sudo docker run -d --name ${APP_NAME} -p 80:3000 ${DOCKER_IMAGE}:latest
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
            echo "❌ Deployment failed."
        }
    }
}
