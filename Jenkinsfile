pipeline {
    agent any

    environment {
        AWS_SERVER_IP = "54.90.221.101" // <-- Update with latest Web Server Public IP
        PEM_FILE = "/var/lib/jenkins/karan.pem"
        REMOTE_USER = "ubuntu"
        DEPLOY_DIR = "/var/www/html/jenkins-deploy"
        DOCKER_IMAGE = "karan-node-app"
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
                sh 'docker build -t $DOCKER_IMAGE .'
            }
        }

        stage('Push to Web Server') {
            steps {
                sh """
                    ssh -i $PEM_FILE -o StrictHostKeyChecking=no $REMOTE_USER@$AWS_SERVER_IP 'sudo mkdir -p $DEPLOY_DIR'
                    scp -i $PEM_FILE -o StrictHostKeyChecking=no docker-compose.yml $REMOTE_USER@$AWS_SERVER_IP:$DEPLOY_DIR/
                    scp -i $PEM_FILE -o StrictHostKeyChecking=no Dockerfile package.json server.js $REMOTE_USER@$AWS_SERVER_IP:$DEPLOY_DIR/
                """
            }
        }

        stage('Deploy on Web Server') {
            steps {
                sh """
                    ssh -i $PEM_FILE -o StrictHostKeyChecking=no $REMOTE_USER@$AWS_SERVER_IP "
                        cd $DEPLOY_DIR &&
                        sudo docker build -t $DOCKER_IMAGE . &&
                        sudo docker stop $DOCKER_IMAGE || true &&
                        sudo docker rm $DOCKER_IMAGE || true &&
                        sudo docker run -d --name $DOCKER_IMAGE -p 3000:3000 $DOCKER_IMAGE
                    "
                """
            }
        }
    }

    post {
        failure {
            echo '❌ Deployment failed.'
        }
        success {
            echo '✅ Deployment successful.'
        }
    }
}
