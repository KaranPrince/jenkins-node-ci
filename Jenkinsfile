pipeline {
    agent any
    environment {
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
        DEPLOY_USER = "ubuntu"
        DEPLOY_HOST = "44.222.203.180"
        PEM_FILE = "/var/lib/jenkins/karan.pem"
        DEPLOY_DIR = "/var/www/html/jenkins-deploy"
        BACKUP_FILE = "/tmp/rollback_backup.tar.gz"
        NODE_ENV = "production"
    }

    stages {

        stage('Checkout Source') {
            steps {
                echo "📥 Pulling latest source code..."
                checkout scm
            }
        }

        stage('Install Dependencies & Test') {
            steps {
                echo "🧪 Installing dependencies & running tests..."
                sh '''
                    npm install
                    npm test || true
                '''
            }
        }

        stage('Inject Build Metadata') {
            steps {
                echo "📝 Injecting build metadata into index.html..."
                script {
                    def now = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
                    sh """
                        sed -i 's|__BUILD_NUMBER__|${BUILD_NUMBER}|g' app/index.html
                        sed -i 's|__GIT_COMMIT__|$(git rev-parse HEAD)|g' app/index.html
                        sed -i 's|__GIT_AUTHOR__|$(git log -1 --pretty=format:%an)|g' app/index.html
                        sed -i 's|__GIT_DATE__|${now}|g' app/index.html
                        sed -i 's|__GIT_MESSAGE__|$(git log -1 --pretty=format:%s)|g' app/index.html
                        sed -i 's|__GIT_BRANCH__|$(git rev-parse --abbrev-ref HEAD)|g' app/index.html
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh "docker build -t jenkins_app:${BUILD_NUMBER} ."
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "🚀 Deploying Docker container to EC2..."
                sh """
                    ssh -i ${PEM_FILE} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                        sudo mkdir -p ${DEPLOY_DIR}

                        # Backup existing container if running
                        if sudo docker ps -q -f name=jenkins_app >/dev/null 2>&1; then
                            sudo docker commit jenkins_app backup_jenkins_app:${BUILD_NUMBER}
                            sudo docker save -o ${BACKUP_FILE} backup_jenkins_app:${BUILD_NUMBER}
                            sudo docker rm -f jenkins_app
                        fi
                    '

                    scp -i ${PEM_FILE} -o StrictHostKeyChecking=no -r ./app ${DEPLOY_USER}@${DEPLOY_HOST}:${DEPLOY_DIR}/

                    ssh -i ${PEM_FILE} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                        cd ${DEPLOY_DIR}
                        docker build -t jenkins_app:${BUILD_NUMBER} .
                        docker run -d --name jenkins_app -p 80:80 jenkins_app:${BUILD_NUMBER}
                    '
                """
            }
        }

        stage('Post-Deploy Verification') {
            steps {
                echo "🔍 Verifying deployment..."
                sh "ssh -i ${PEM_FILE} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} 'docker ps | grep jenkins_app'"
            }
        }
    }

    post {
        failure {
            echo "⚠️ Deployment failed, initiating rollback..."
            sh """
                ssh -i ${PEM_FILE} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                    if [ -f ${BACKUP_FILE} ]; then
                        sudo docker load -i ${BACKUP_FILE}
                        sudo docker rm -f jenkins_app || true
                        sudo docker run -d --name jenkins_app -p 80:80 backup_jenkins_app:${BUILD_NUMBER}
                        echo "✅ Rollback completed."
                    else
                        echo "⚠️ No backup found to restore."
                    fi
                '
            """
        }
    }
}
