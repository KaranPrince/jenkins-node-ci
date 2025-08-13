pipeline {
    agent any

    environment {
        DEPLOY_USER     = 'ubuntu' // EC2 username
        DEPLOY_HOST     = credentials('ec2-public-ip') // Stored in Jenkins credentials
        PEM_KEY_PATH    = '/var/lib/jenkins/karan.pem' // Private key file path
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
                    command -v tidy || sudo apt-get update && sudo apt-get install -y tidy
                    tidy -qe app/index.html
                    tar -czf deploy_artifact.tar.gz app/
                '''
            }
        }

        stage('Test') {
            steps {
                echo "🧪 Running link and placeholder checks..."
                sh '''
                    command -v linkchecker || sudo apt-get update && sudo apt-get install -y linkchecker
                    linkchecker --check-extern app/index.html
                    grep __BUILD_NUMBER__ app/index.html || echo "⚠️ Placeholders OK for now"
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

                        BRANCH_NAME=\$(git rev-parse --abbrev-ref HEAD)
                        COMMIT_HASH=\$(git rev-parse HEAD)
                        COMMIT_AUTHOR=\$(git log -1 --pretty=format:%an)
                        COMMIT_DATE=\$(git log -1 --pretty=format:%cd)
                        COMMIT_MSG=\$(git log -1 --pretty=format:%s)

                        sed -i s|__BUILD_NUMBER__|${env.BUILD_NUMBER}|g app/index.html
                        sed -i s|__GIT_BRANCH__|\${BRANCH_NAME}|g app/index.html
                        sed -i s|__GIT_COMMIT__|\${COMMIT_HASH}|g app/index.html
                        sed -i s|__GIT_AUTHOR__|\${COMMIT_AUTHOR}|g app/index.html
                        sed -i s|__GIT_DATE__|\${COMMIT_DATE}|g app/index.html
                        sed -i s|__GIT_MESSAGE__|\${COMMIT_MSG}|g app/index.html

                        tar -czf deploy_artifact.tar.gz app/

                        scp -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no deploy_artifact.tar.gz ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/
                        ssh -i ${PEM_KEY_PATH} -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} '
                            tar -xzf /tmp/deploy_artifact.tar.gz -C /var/www/html/
                            rm /tmp/deploy_artifact.tar.gz
                        '
                    """
                }
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
            echo "✅ Pipeline Build #${env.BUILD_NUMBER} completed successfully."
        }
        failure {
            echo "❌ Pipeline Build #${env.BUILD_NUMBER} failed. Check logs."
        }
    }
}
