pipeline {
    agent any

    environment {
        DEPLOY_USER  = 'ubuntu'
        DEPLOY_HOST  = '44.222.203.180'
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem'
        BUILD_TIME   = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
    }

    stages {

        stage('Checkout Source') {
            steps {
                echo "📥 Pulling latest source code from GitHub..."
                checkout scm
            }
        }

        stage('Validate HTML') {
            steps {
                echo "🔍 Validating HTML syntax..."
                sh '''
                    if ! command -v tidy &> /dev/null; then
                        sudo apt-get update
                        sudo apt-get install -y tidy
                    fi
                    tidy -qe app/index.html
                '''
            }
        }

        stage('Inject Build Metadata') {
            steps {
                echo "📝 Inserting build and Git metadata into HTML..."
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
                    """
                }
            }
        }

        stage('Package Artifact') {
            steps {
                echo "📦 Packaging application for deployment..."
                sh 'tar -czf deploy_artifact.tar.gz app/'
            }
        }

        stage('Backup Current Deployment') {
            steps {
                echo "💾 Backing up current deployment on server..."
                sh '''
                    sudo chown jenkins:jenkins ${PEM_KEY_PATH}
                    sudo chmod 400 ${PEM_KEY_PATH}

                    ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                        if [ -d /var/www/html/jenkins-deploy ]; then
                            sudo tar -czf /tmp/rollback_backup.tar.gz -C /var/www/html jenkins-deploy
                        fi
                    '
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "🚀 Deploying to EC2 Web Server..."
                sh '''
                    scp -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no deploy_artifact.tar.gz ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/ || exit 1

                    ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                        sudo mkdir -p /var/www/html/jenkins-deploy &&
                        sudo tar -xzf /tmp/deploy_artifact.tar.gz -C /var/www/html/jenkins-deploy --strip-components=1 &&
                        sudo rm /tmp/deploy_artifact.tar.gz &&
                        sudo systemctl restart apache2
                    ' || exit 1
                '''
            }
        }

        stage('Post-Deploy Verification') {
            steps {
                echo "🔍 Running post-deployment health check..."
                sh '''
                    STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}" http://${DEPLOY_HOST}/jenkins-deploy/)
                    if [ "$STATUS_CODE" -ne 200 ]; then
                        echo "❌ Deployment verification failed! Rolling back..."
                        exit 1
                    fi
                    echo "✅ Deployment verification passed."
                '''
            }
        }
    }

    post {
        failure {
            echo "♻️ Restoring previous version from backup..."
            sh '''
                ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                    if [ -f /tmp/rollback_backup.tar.gz ]; then
                        sudo rm -rf /var/www/html/jenkins-deploy &&
                        sudo tar -xzf /tmp/rollback_backup.tar.gz -C /var/www/html &&
                        sudo systemctl restart apache2
                        echo "✅ Rollback completed."
                    else
                        echo "⚠️ No rollback backup found. Cannot restore."
                    fi
                '
            '''
        }
        success {
            echo "✅ Deployment pipeline completed successfully."
        }
    }
}
