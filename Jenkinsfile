pipeline {
    agent any

    environment {
        DEPLOY_USER  = 'ubuntu'
        DEPLOY_HOST  = '44.222.203.180'
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem'
        DEPLOY_DIR   = '/var/www/html/jenkins-deploy'
        BACKUP_FILE  = '/tmp/rollback_backup.tar.gz'
        BUILD_TIME   = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
        ENVIRONMENT  = 'STAGING'
    }

    stages {

        stage('Setup Environment') {
            steps {
                echo "⚙️ Ensuring Node.js, NPM, and Docker are available..."
                sh '''
                    command -v node
                    command -v npm
                    command -v docker
                    node -v
                    npm -v
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
                    if ! command -v tidy &> /dev/null; then
                        sudo apt-get update
                        sudo apt-get install -y tidy
                    fi
                    tidy -qe app/index.html || true
                '''
            }
        }

        stage('Unit & Integration Tests') {
            steps {
                echo "🧪 Running unit & integration tests..."
                sh '''
                    if [ -f package.json ]; then
                        npm install
                        npm test
                    fi
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
                        sed -i 's|__BUILD_NUMBER__|${BUILD_NUMBER}|g' app/index.html
                        sed -i 's|__GIT_BRANCH__|${branch}|g' app/index.html
                        sed -i 's|__GIT_COMMIT__|${commit}|g' app/index.html
                        sed -i 's|__GIT_AUTHOR__|${author}|g' app/index.html
                        sed -i 's|__GIT_DATE__|${BUILD_TIME}|g' app/index.html
                        sed -i 's|__GIT_MESSAGE__|${msg}|g' app/index.html
                        sed -i 's|__ENVIRONMENT__|${ENVIRONMENT}|g' app/index.html
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
                    ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                        sudo mkdir -p ${DEPLOY_DIR}

                        # Backup existing container if running
                        if sudo docker ps -q -f name=jenkins_app >/dev/null 2>&1; then
                            sudo docker commit jenkins_app backup_jenkins_app:${BUILD_NUMBER}
                            sudo docker save -o ${BACKUP_FILE} backup_jenkins_app:${BUILD_NUMBER}
                            sudo docker rm -f jenkins_app
                        fi
                    "

                    # Build new Docker image on EC2
                    scp -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no deploy_artifact.tar.gz ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/
                    ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                        cd /tmp
                        rm -rf app && tar -xzf deploy_artifact.tar.gz
                        docker build -t jenkins_app:latest .
                        docker run -d --name jenkins_app -p 80:80 jenkins_app:latest
                    "
                """
            }
        }

        stage('Post-Deploy Verification') {
            steps {
                echo "🔍 Running post-deployment health check..."
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
            echo "♻️ Rolling back deployment..."
            sh """
                ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                    if [ -f ${BACKUP_FILE} ]; then
                        docker load -i ${BACKUP_FILE}
                        docker rm -f jenkins_app || true
                        docker run -d --name jenkins_app -p 80:80 backup_jenkins_app:${BUILD_NUMBER}
                        echo '✅ Rollback completed.'
                    else
                        echo '⚠️ No backup found to restore.'
                    fi
                "
            """
        }
        success {
            echo "✅ Deployment pipeline completed successfully."
        }
    }
}
