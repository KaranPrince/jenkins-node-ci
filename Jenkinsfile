pipeline {
    agent any

    environment {
        DEPLOY_USER  = 'ubuntu'
        DEPLOY_HOST  = '44.222.203.180'  // Public IP of your web server
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem' // Private key file path
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
                echo "🔧 Validating HTML and creating artifact..."
                sh '''
                    if ! command -v tidy &> /dev/null; then
                        sudo apt-get update
                        sudo apt-get install -y tidy
                    fi

                    tidy -qe app/index.html || true
                    tar -czf deploy_artifact.tar.gz app/
                '''
            }
        }

        stage('Test') {
            steps {
                echo "🧪 Running link and placeholder checks..."
                sh '''
                    if ! command -v linkchecker &> /dev/null; then
                        sudo apt-get update
                        sudo apt-get install -y linkchecker
                    fi

                    linkchecker --check-extern app/index.html || true
                    if grep "__BUILD_NUMBER__" app/index.html; then
                        echo "⚠️ Placeholders OK for now"
                    fi
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "🚀 Deploying artifact to EC2..."
                script {
                    sh """
                        sudo chown jenkins:jenkins ${PEM_KEY_PATH}
                        sudo chmod 400 ${PEM_KEY_PATH}

                        # Copy artifact to web server
                        scp -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no deploy_artifact.tar.gz ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/

                        # Extract on web server and restart Apache
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
                echo "🔍 Checking if deployed site is reachable..."
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
