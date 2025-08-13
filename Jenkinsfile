pipeline {
    agent any

    environment {
        DEPLOY_HOST = credentials('ec2-public-ip')
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem'
        REMOTE_DEPLOY_DIR = '/var/www/html/jenkins-deploy'
        BACKUP_DIR = '/tmp/jenkins-backup'
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                echo '🔄 Fetching code from GitHub...'
                checkout scm
            }
        }

        stage('HTML Validation') {
            steps {
                echo '🔧 Validating HTML file...'
                sh '''
                    if ! command -v tidy >/dev/null; then
                        sudo apt-get update
                        sudo apt-get install -y tidy
                    fi
                    tidy -qe app/index.html
                '''
            }
        }

        stage('Inject Build Metadata') {
            steps {
                echo '📝 Injecting build metadata into HTML...'
                script {
                    def gitBranch = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    def gitCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    def gitAuthor = sh(script: 'git log -1 --pretty=format:%an', returnStdout: true).trim()
                    def gitDate = sh(script: 'git log -1 --pretty=format:%cd', returnStdout: true).trim()
                    def gitMessage = sh(script: 'git log -1 --pretty=format:%s', returnStdout: true).trim()

                    sh """
                        sed -i 's|__BUILD_NUMBER__|${BUILD_NUMBER}|g' app/index.html
                        sed -i 's|__GIT_BRANCH__|${gitBranch}|g' app/index.html
                        sed -i 's|__GIT_COMMIT__|${gitCommit}|g' app/index.html
                        sed -i 's|__GIT_AUTHOR__|${gitAuthor}|g' app/index.html
                        sed -i 's|__GIT_DATE__|${gitDate}|g' app/index.html
                        sed -i 's|__GIT_MESSAGE__|${gitMessage}|g' app/index.html
                    """
                }
            }
        }

        stage('Package Artifact') {
            steps {
                echo '📦 Creating deployment package...'
                sh 'tar -czf deploy_artifact.tar.gz app/'
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo '🚀 Deploying to EC2...'
                sh """
                    sudo chown jenkins:jenkins ${PEM_KEY_PATH}
                    sudo chmod 400 ${PEM_KEY_PATH}

                    ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ubuntu@${DEPLOY_HOST} '
                        mkdir -p ${BACKUP_DIR} &&
                        if [ -d ${REMOTE_DEPLOY_DIR} ]; then
                            sudo rm -rf ${BACKUP_DIR}/* &&
                            sudo cp -r ${REMOTE_DEPLOY_DIR}/* ${BACKUP_DIR}/
                        fi
                    '

                    scp -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} deploy_artifact.tar.gz ubuntu@${DEPLOY_HOST}:/tmp/

                    ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ubuntu@${DEPLOY_HOST} '
                        sudo mkdir -p ${REMOTE_DEPLOY_DIR} &&
                        sudo tar -xzf /tmp/deploy_artifact.tar.gz -C ${REMOTE_DEPLOY_DIR} --strip-components=1
                    '
                """
            }
        }

        stage('Post-Deploy Health Check') {
            steps {
                echo '🔍 Checking deployment health...'
                script {
                    def statusCode = sh(
                        script: """
                            curl -o /dev/null -s -w "%{http_code}" http://${DEPLOY_HOST}/jenkins-deploy/
                        """,
                        returnStdout: true
                    ).trim()

                    if (statusCode != "200") {
                        error("❌ Health check failed with status code: ${statusCode}")
                    } else {
                        echo "✅ Deployment is healthy."
                    }
                }
            }
        }
    }

    post {
        failure {
            echo '⚠️ Deployment failed. Rolling back to last working version...'
            sh """
                ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ubuntu@${DEPLOY_HOST} '
                    if [ -d ${BACKUP_DIR} ] && [ "$(ls -A ${BACKUP_DIR})" ]; then
                        sudo rm -rf ${REMOTE_DEPLOY_DIR}/* &&
                        sudo cp -r ${BACKUP_DIR}/* ${REMOTE_DEPLOY_DIR}/
                        echo "✅ Rollback complete."
                    else
                        echo "⚠️ No backup found to rollback."
                    fi
                '
            """
        }
        success {
            echo "🎉 Build #${BUILD_NUMBER} completed successfully!"
        }
    }
}
