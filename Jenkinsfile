pipeline {
    agent any

    environment {
        DEPLOY_USER  = 'ubuntu'
        DEPLOY_HOST  = '44.222.203.180'
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem'
        BUILD_TIME   = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
        ENVIRONMENT  = 'STAGING' // example: DEV, STAGE, PROD
    }

    stages {

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
                    command -v tidy &>/dev/null || (sudo apt-get update && sudo apt-get install -y tidy)
                    tidy -qe app/index.html
                '''
            }
        }

        stage('Unit & Integration Tests') {
            steps {
                echo "🧪 Running tests..."
                sh '''
                    set -e
                    # Node.js backend tests
                    if [ -f package.json ]; then
                        npm install
                        npm test || exit 1
                    fi
                    # HTML validation already done
                '''
            }
        }

        stage('Inject Build Metadata & Env Vars') {
            steps {
                echo "📝 Injecting metadata & environment variables..."
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
                        sed -i "s|__ENV__|${ENVIRONMENT}|g" app/index.html
                    """
                }
            }
        }

        stage('Package Artifact') {
            steps {
                echo "📦 Packaging artifact..."
                sh 'tar -czf deploy_artifact.tar.gz app/'
            }
        }

        stage('Deploy to EC2 via Docker') {
            steps {
                echo "🚀 Deploying via Docker..."
                sh '''
                    set -e
                    PEM=${PEM_KEY_PATH}
                    USER=${DEPLOY_USER}
                    HOST=${DEPLOY_HOST}

                    ssh -i $PEM -o StrictHostKeyChecking=no $USER@$HOST '
                        # Backup if exists
                        if [ -d /var/www/html/jenkins-deploy ]; then
                            sudo tar -czf /tmp/rollback_backup.tar.gz -C /var/www/html jenkins-deploy
                            echo "💾 Backup created."
                        else
                            echo "ℹ️ No existing deployment to backup."
                        fi

                        # Ensure Docker installed
                        command -v docker &>/dev/null || (sudo apt-get update && sudo apt-get install -y docker.io)

                        # Remove old container & directory
                        sudo docker rm -f jenkins_app || true
                        sudo rm -rf /var/www/html/jenkins-deploy
                        sudo mkdir -p /var/www/html/jenkins-deploy
                    '

                    # Build Docker image locally and copy to server
                    docker build -t jenkins_app_image .
                    docker save jenkins_app_image | bzip2 | ssh -i $PEM $USER@$HOST 'bunzip2 | docker load'

                    # Run container
                    ssh -i $PEM -o StrictHostKeyChecking=no $USER@$HOST '
                        sudo docker run -d --name jenkins_app -p 80:80 -v /var/www/html/jenkins-deploy:/usr/share/nginx/html jenkins_app_image
                    '
                '''
            }
        }

    }

    post {
        failure {
            echo "♻️ Rolling back deployment..."
            sh '''
                PEM=${PEM_KEY_PATH}
                USER=${DEPLOY_USER}
                HOST=${DEPLOY_HOST}
                backup_file=/tmp/rollback_backup.tar.gz

                ssh -i $PEM -o StrictHostKeyChecking=no $USER@$HOST '
                    if [ -f $backup_file ]; then
                        sudo rm -rf /var/www/html/jenkins-deploy &&
                        sudo tar -xzf $backup_file -C /var/www/html &&
                        sudo docker rm -f jenkins_app || true
                        echo "✅ Rollback completed."
                    else
                        echo "⚠️ No backup found to restore."
                    fi
                '
            '''
        }
        success {
            echo "🎉 Deployment succeeded!"
        }
    }
}
