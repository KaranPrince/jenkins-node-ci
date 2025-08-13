pipeline {
    agent any

    environment {
        DEPLOY_USER = 'ubuntu'
        DEPLOY_HOST = credentials('ec2-host') // String Credential with EC2 Public IP/DNS
        REMOTE_DEPLOY_DIR = '/var/www/html/jenkins-deploy'
        LOCAL_INDEX_HTML = 'app/index.html'
        ARTIFACT_NAME = 'deploy_artifact.tar.gz'
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
                echo '🔧 Validating HTML and creating artifact...'
                sh 'command -v tidy >/dev/null 2>&1 || sudo apt-get update && sudo apt-get install -y tidy'
                sh "tidy -qe ${LOCAL_INDEX_HTML} || true"
                sh "tar -czf ${ARTIFACT_NAME} app/"
            }
        }

        stage('Test') {
            steps {
                echo '🧪 Running link and placeholder checks...'
                sh 'command -v linkchecker >/dev/null 2>&1 || sudo apt-get update && sudo apt-get install -y linkchecker'
                sh "linkchecker --check-extern ${LOCAL_INDEX_HTML} || true"
                sh "grep '__BUILD_NUMBER__' ${LOCAL_INDEX_HTML} && echo '⚠️ Placeholders OK for now'"
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo '🚀 Deploying artifact to EC2...'
                sshagent(['ec2-ssh-key']) { // SSH Username with Private Key credential
                    script {
                        def gitBranch = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                        def gitCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                        def gitAuthor = sh(script: 'git log -1 --pretty=format:"%an"', returnStdout: true).trim()
                        def gitDate = sh(script: 'git log -1 --pretty=format:"%cd"', returnStdout: true).trim()
                        def gitMessage = sh(script: 'git log -1 --pretty=format:"%s"', returnStdout: true).trim()

                        // Inject build info into HTML
                        sh """
                            sed -i "s|__BUILD_NUMBER__|${env.BUILD_NUMBER}|g" ${LOCAL_INDEX_HTML}
                            sed -i "s|__GIT_BRANCH__|${gitBranch}|g" ${LOCAL_INDEX_HTML}
                            sed -i "s|__GIT_COMMIT__|${gitCommit}|g" ${LOCAL_INDEX_HTML}
                            sed -i "s|__GIT_AUTHOR__|${gitAuthor}|g" ${LOCAL_INDEX_HTML}
                            sed -i "s|__GIT_DATE__|${gitDate}|g" ${LOCAL_INDEX_HTML}
                            sed -i "s|__GIT_MESSAGE__|${gitMessage}|g" ${LOCAL_INDEX_HTML}
                            tar -czf ${ARTIFACT_NAME} app/
                        """

                        // Deploy
                        sh """
                            ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} 'mkdir -p ${REMOTE_DEPLOY_DIR}'
                            scp -o StrictHostKeyChecking=no ${ARTIFACT_NAME} ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/
                            ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} 'tar -xzf /tmp/${ARTIFACT_NAME} -C ${REMOTE_DEPLOY_DIR} --strip-components=1'
                        """
                    }
                }
            }
        }

        stage('Post-Deploy Health Check') {
            steps {
                echo '🔍 Verifying deployment...'
                script {
                    def status = sh(script: "curl -o /dev/null -s -w '%{http_code}' http://${DEPLOY_HOST}/jenkins-deploy/", returnStdout: true).trim()

                    if (status == '200') {
                        echo "✅ Site is live and returned HTTP ${status}"
                        sh "curl -s http://${DEPLOY_HOST}/jenkins-deploy/ | grep 'Jenkins Deployment Successful!' && echo '✅ Content verification passed!'"
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
