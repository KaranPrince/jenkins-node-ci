pipeline {
    agent any

    environment {
        DEPLOY_USER  = 'ubuntu'
        DEPLOY_HOST  = '44.222.203.180'
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem'
        BUILD_TIME   = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
        ENVIRONMENT  = 'STAGING'
        DEPLOY_DIR   = '/var/www/html/jenkins-deploy'
        BACKUP_FILE  = '/tmp/rollback_backup.tar.gz'
        DOCKER_IMAGE = "jenkins_app:${BUILD_NUMBER}"
    }

    stages {

        stage('Setup Environment') {
            steps {
                echo "⚙️ Ensuring Node.js, NPM, and Docker are available..."
                sh '''
                    set -e
                    command -v node &>/dev/null || (curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs)
                    command -v npm &>/dev/null || (sudo apt-get install -y npm)
                    node -v
                    npm -v
                    command -v docker &>/dev/null || (sudo apt-get install -y docker.io)
                    docker --version
                '''
            }
        }

        stage('Checkout Source') {
            steps {
                echo "📥 Pulling latest source code..."
                checkout scm
            }
        }

        stage('Validate HTML') {
            steps {
                echo "🔍 Validating HTML..."
                sh '''
                    set -e
                    command -v tidy &>/dev/null || sudo apt-get install -y tidy
                    tidy -qe app/index.html
                '''
            }
        }

        stage('Unit & Integration Tests') {
            steps {
                echo "🧪 Running unit & integration tests..."
                sh '''
                    set -e
                    [ -f package.json ] && npm install && npm test || echo "⚠️ No Node.js project detected"
                '''
            }
        }

        stage('Inject Build Metadata & Env Vars') {
            steps {
                echo "📝 Injecting build metadata and environment variables..."
                script {
                    def branch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def commit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    def author = sh(script: "git log -1 --pretty=format:%an", returnStdout: true).trim()
                    def msg    = sh(script: "git log -1 --pretty=format:%s", returnStdout: true).trim()

                    sh """
                        sed -i "s|__BUILD_NUMBER__|${env.BUILD_NUMBER}|g" app/index.html
                        sed -i "s|__GIT_BRANCH__|${branch}|g" app/index.html
                        sed -i "s|__GIT_COMMIT__|${commit}|g" app/index.html
                        sed -i "s|__GIT_AUTHOR__|${author}|g" app/index.html
                        sed -i "s|__GIT_DATE__|${BUILD_TIME}|g" app/index.html
                        sed -i "s|__GIT_MESSAGE__|${msg}|g" app/index.html
                        sed -i "s|__ENVIRONMENT__|${ENVIRONMENT}|g" app/index.html
                    """
                }
            }
        }

        stage('Package Artifact') {
            steps {
                echo "📦 Packaging application..."
                sh 'tar -czf deploy_artifact.tar.gz app/'
            }
        }

        stage('Deploy to EC2 via Docker') {
            steps {
                echo "🚀 Deploying Docker container to EC2..."
                sh """
                    ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                        # Create deploy dir if missing
                        sudo mkdir -p ${DEPLOY_DIR}
                        # Backup current deployment (if exists)
                        if [ -f ${BACKUP_FILE} ]; then sudo rm -f ${BACKUP_FILE}; fi
                        if [ "$(sudo docker ps -q -f name=jenkins_app)" != "" ]; then
                            sudo docker commit jenkins_app backup_jenkins_app:${BUILD_NUMBER} &&
                            sudo docker save -o ${BACKUP_FILE} backup_jenkins_app:${BUILD_NUMBER}
                        fi
                        # Remove old container
                        sudo docker rm -f jenkins_app || true
                    '

                    # Build Docker image locally
                    docker build -t ${DOCKER_IMAGE} .

                    # Save and transfer image to EC2
                    docker save ${DOCKER_IMAGE} | bzip2 | ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} 'bunzip2 | sudo docker load'

                    # Run container on EC2
                    ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                        sudo docker run -d --name jenkins_app -p 80:80 ${DOCKER_IMAGE}
                    '
                """
            }
        }

        stage('Post-Deploy Verification') {
            steps {
                echo "🔍 Running deployment verification..."
                sh """
                    STATUS_CODE=\$(curl -o /dev/null -s -w "%{http_code}" http://${DEPLOY_HOST}/)
                    if [ "\$STATUS_CODE" -ne 200 ]; then
                        echo "❌ Deployment verification failed!"
                        exit 1
                    fi
                    echo "✅ Deployment verification passed."
                """
            }
        }

    }

    post {
        failure {
            echo "♻️ Rollback deployment..."
            sh """
                ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                    # Restore previous Docker container if backup exists
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

        success {
            echo "✅ Pipeline completed successfully."
        }
    }
}
