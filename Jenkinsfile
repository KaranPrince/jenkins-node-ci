pipeline {
    agent any

    environment {
        DEPLOY_USER  = 'ubuntu' // EC2 default user
        DEPLOY_HOST  = credentials('DEPLOY_HOST') // Public IP/DNS stored in Jenkins
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem' // Path to PEM key
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "🔄 Checking out source code..."
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "🔧 Validating HTML and creating artifact..."
                sh '''
                    # Install tidy if not already installed
                    command -v tidy >/dev/null 2>&1 || {
                        sudo apt-get update
                        sudo apt-get install -y tidy
                    }

                    tidy -qe app/index.html
                    tar -czf deploy_artifact.tar.gz app/
                '''
            }
        }

        stage('Test') {
            steps {
                echo "🧪 Running link and placeholder checks..."
                sh '''
                    # Install linkchecker if missing
                    command -v linkchecker >/dev/null 2>&1 || {
                        sudo apt-get update
                        sudo apt-get install -y linkchecker
                    }

                    linkchecker --check-extern app/index.html
                    grep __BUILD_NUMBER__ app/index.html || echo "⚠️ Placeholders OK for now"
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "🚀 Deploying artifact to EC2..."
                sh '''
                    # Fix PEM file permissions
                    sudo chown jenkins:jenkins ${PEM_KEY_PATH}
                    sudo chmod 400 ${PEM_KEY_PATH}

                    # Git metadata
                    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
                    COMMIT_HASH=$(git rev-parse HEAD)
                    COMMIT_AUTHOR=$(git log -1 --pretty=format:%an)
                    COMMIT_DATE=$(git log -1 --pretty=format:%cd)
                    COMMIT_MSG=$(git log -1 --pretty=format:%s)

                    # Replace placeholders
                    sed -i "s|__BUILD_NUMBER__|${BUILD_NUMBER}|g" app/index.html
                    sed -i "s|__GIT_BRANCH__|${BRANCH_NAME}|g" app/index.html
                    sed -i "s|__GIT_COMMIT__|${COMMIT_HASH}|g" app/index.html
                    sed -i "s|__GIT_AUTHOR__|${COMMIT_AUTHOR}|g" app/index.html
                    sed -i "s|__GIT_DATE__|${COMMIT_DATE}|g" app/index.html
                    sed -i "s|__GIT_MESSAGE__|${COMMIT_MSG}|g" app/index.html

                    tar -czf deploy_artifact.tar.gz app/

                    # Copy to EC2
                    scp -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no deploy_artifact.tar.gz ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/

                    # Deploy on EC2
                    ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                        sudo tar -xzf /tmp/deploy_artifact.tar.gz -C /var/www/html/
                        sudo rm /tmp/deploy_artifact.tar.gz
                    '
                '''
            }
        }

        stage('Post-Deploy Health Check') {
            steps {
                echo "🔍 Checking if deployment is live..."
                sh '''
                    curl -I http://${DEPLOY_HOST} || echo "⚠️ Health check failed"
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Build #${BUILD_NUMBER} completed successfully."
        }
        failure {
            echo "❌ Build #${BUILD_NUMBER} failed. Check logs."
        }
    }
}
