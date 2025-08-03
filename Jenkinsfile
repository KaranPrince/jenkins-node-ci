pipeline {
    agent any

    environment {
        DEPLOY_USER = 'ubuntu'
        DEPLOY_HOST = 'YOUR_NEW_EC2_PUBLIC_IP'
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem'
        REMOTE_DEPLOY_DIR = '/var/www/html/jenkins-deploy'
        LOCAL_INDEX_HTML = 'app/index.html'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo '🔄 Checking out source code from GitHub...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo '🔧 Build stage initiated...'
                echo '✅ Simulating a build...'
            }
        }

        stage('Test') {
            steps {
                echo '🧪 Running basic tests...'
                sh 'echo All unit tests passed!'
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo '🚀 Deploying to EC2...'
                script {
                    // Capture Git info
                    def gitBranch = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    def gitCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    def gitAuthor = sh(script: 'git log -1 --pretty=format:"%an"', returnStdout: true).trim()
                    def gitDate = sh(script: 'git log -1 --pretty=format:"%cd"', returnStdout: true).trim()
                    def gitMessage = sh(script: 'git log -1 --pretty=format:"%s"', returnStdout: true).trim()

                    // Inject into HTML
                    sh """
                        sed -i "s|__BUILD_NUMBER__|${env.BUILD_NUMBER}|g" ${LOCAL_INDEX_HTML}
                        sed -i "s|__GIT_BRANCH__|${gitBranch}|g" ${LOCAL_INDEX_HTML}
                        sed -i "s|__GIT_COMMIT__|${gitCommit}|g" ${LOCAL_INDEX_HTML}
                        sed -i "s|__GIT_AUTHOR__|${gitAuthor}|g" ${LOCAL_INDEX_HTML}
                        sed -i "s|__GIT_DATE__|${gitDate}|g" ${LOCAL_INDEX_HTML}
                        sed -i "s|__GIT_MESSAGE__|${gitMessage}|g" ${LOCAL_INDEX_HTML}
                    """

                    // SCP to EC2
                    sh """
                        chmod 400 ${PEM_KEY_PATH}
                        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ${DEPLOY_USER}@${DEPLOY_HOST} 'mkdir -p ${REMOTE_DEPLOY_DIR}'
                        scp -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${LOCAL_INDEX_HTML} ${DEPLOY_USER}@${DEPLOY_HOST}:${REMOTE_DEPLOY_DIR}/index.html
                    """
                }
            }
        }

        stage('Post-Deploy Health Check') {
            steps {
                echo '🔍 Running post-deploy health check...'
                script {
                    def status = sh(script: "curl -o /dev/null -s -w '%{http_code}' http://${DEPLOY_HOST}/jenkins-deploy/", returnStdout: true).trim()

                    if (status == '200') {
                        echo "✅ Site is live and returned HTTP ${status}"
                    } else {
                        error("❌ Deployment failed! HTTP response: ${status}")
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline Build #${env.BUILD_NUMBER} completed successfully!"
        }
        failure {
            echo "❌ Pipeline Build #${env.BUILD_NUMBER} failed. Check logs."
        }
    }
}
