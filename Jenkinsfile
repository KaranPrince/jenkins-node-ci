pipeline {
    agent any

    environment {
        DEPLOY_USER  = 'ubuntu'
        DEPLOY_HOST  = '44.222.203.180'
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem'
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "🔄 Checking out source code from GitHub..."
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "🔧 Validating HTML..."
                sh '''
                    if ! command -v tidy &> /dev/null; then
                        sudo apt-get update
                        sudo apt-get install -y tidy
                    fi
                    tidy -qe app/index.html || true
                '''
            }
        }

        stage('Inject Build Metadata') {
            steps {
                echo "📝 Replacing placeholders with build metadata..."
                script {
                    def branch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def commit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    def author = sh(script: "git log -1 --pretty=format:%an", returnStdout: true).trim()
                    def date   = sh(script: "git log -1 --pretty=format:%cd", returnStdout: true).trim()
                    def msg    = sh(script: "git log -1 --pretty=format:%s", returnStdout: true).trim()

                    sh """
                        sed -i s|__BUILD_NUMBER__|${env.BUILD_NUMBER}|g app/index.html
                        sed -i s|__GIT_BRANCH__|${branch}|g app/index.html
                        sed -i s|__GIT_COMMIT__|${commit}|g app/index.html
                        sed -i s|__GIT_AUTHOR__|${author}|g app/index.html
                        sed -i s|__GIT_DATE__|${date}|g app/index.html
                        sed -i s|__GIT_MESSAGE__|'${msg}'|g app/index.html
                    """
                }
            }
        }

        stage('Package Artifact') {
            steps {
                echo "📦 Creating deployable artifact..."
                sh 'tar -czf deploy_artifact.tar.gz app/'
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "🚀 Deploying artifact to EC2..."
                script {
                    sh """
                        sudo chown jenkins:jenkins ${PEM_KEY_PATH}
                        sudo chmod 400 ${PEM_KEY_PATH}

                        scp -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no deploy_artifact.tar.gz ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/

                        ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                            sudo mkdir -p /var/www/html/jenkins-deploy
                            sudo tar -xzf /tmp/deploy_artifact.tar.gz -C /var/www/html/jenkins-deploy --strip-components=1
                            sudo rm /tmp/deploy_artifact.tar.gz
                            sudo systemctl restart apache2
                        '
                    """
                }
            }
        }

        stage('Post-Deploy Health Check') {
            steps {
                echo "🔍 Checking deployment..."
                sh "curl -I http://${DEPLOY_HOST}/jenkins-deploy/ | head -n 1"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline Build #${env.BUILD_NUMBER} completed successfully."
        }
        failure {
            echo "❌ Pipeline Build #${env.BUILD_NUMBER} failed. Check logs."
        }
    }
}
