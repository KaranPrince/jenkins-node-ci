pipeline {
    agent any

    environment {
        DEPLOY_DIR = "/var/www/html/jenkins-deploy"
        BACKUP_FILE = "/tmp/rollback_backup.tar.gz"
        ENVIRONMENT = "STAGING"
        GIT_BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
        GIT_COMMIT = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
        GIT_AUTHOR = sh(script: "git log -1 --pretty=format:%an", returnStdout: true).trim()
        GIT_DATE = sh(script: "git log -1 --pretty=format:%cd --date=iso", returnStdout: true).trim()
        GIT_MESSAGE = sh(script: "git log -1 --pretty=format:%s", returnStdout: true).trim()
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Setup Environment') {
            steps {
                echo "⚙️ Checking Node.js, NPM, and Docker..."
                sh 'node -v && npm -v && docker --version'
            }
        }

        stage('Checkout Source') {
            steps {
                echo "📥 Pulling latest source code..."
                checkout scm
            }
        }

        stage('Unit Tests') {
            steps {
                echo "🧪 Running unit tests..."
                sh '''
                    npm install
                    npm test || true
                '''
            }
        }

        stage('Inject Build Metadata') {
            steps {
                echo "📝 Injecting build metadata into index.html..."
                sh """
                    sed -i 's|__BUILD_NUMBER__|${BUILD_NUMBER}|g' app/index.html
                    sed -i 's|__GIT_BRANCH__|${GIT_BRANCH}|g' app/index.html
                    sed -i 's|__GIT_COMMIT__|${GIT_COMMIT}|g' app/index.html
                    sed -i 's|__GIT_AUTHOR__|${GIT_AUTHOR}|g' app/index.html
                    sed -i 's|__GIT_DATE__|${GIT_DATE}|g' app/index.html
                    sed -i 's|__GIT_MESSAGE__|${GIT_MESSAGE}|g' app/index.html
                    sed -i 's|__ENVIRONMENT__|${ENVIRONMENT}|g' app/index.html
                """
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
                script {
                    def remote = "ubuntu@54.90.221.101"
                    def key = "/var/lib/jenkins/karan.pem"

                    // Create deploy directory on EC2
                    sh "ssh -i ${key} -o StrictHostKeyChecking=no ${remote} 'sudo mkdir -p ${DEPLOY_DIR}'"

                    // Backup existing container if running
                    sh """
                        ssh -i ${key} -o StrictHostKeyChecking=no ${remote} '
                            if sudo docker ps -q -f name=jenkins_app >/dev/null 2>&1; then
                                sudo docker commit jenkins_app backup_jenkins_app:${BUILD_NUMBER}
                                sudo docker save -o ${BACKUP_FILE} backup_jenkins_app:${BUILD_NUMBER}
                                sudo docker rm -f jenkins_app
                            fi
                        '
                    """

                    // Copy app and build Docker image
                    sh "scp -i ${key} -r app ${remote}:${DEPLOY_DIR}/"
                    sh """
                        ssh -i ${key} -o StrictHostKeyChecking=no ${remote} '
                            cd ${DEPLOY_DIR}
                            sudo docker build -t jenkins_app:${BUILD_NUMBER} .
                            sudo docker run -d --name jenkins_app -p 80:80 jenkins_app:${BUILD_NUMBER}
                        '
                    """
                }
            }
        }

        stage('Post-Deploy Verification') {
            steps {
                echo "🔍 Verifying deployment..."
                sh "ssh -i /var/lib/jenkins/karan.pem ubuntu@54.90.221.101 'docker ps'"
            }
        }
    }

    post {
        failure {
            echo "⚠️ Deployment failed, rolling back..."
            sh """
                ssh -i /var/lib/jenkins/karan.pem -o StrictHostKeyChecking=no ubuntu@44.222.203.180 '
                    if [ -f ${BACKUP_FILE} ]; then
                        sudo docker load -i ${BACKUP_FILE}
                        sudo docker rm -f jenkins_app || true
                        sudo docker run -d --name jenkins_app -p 80:80 backup_jenkins_app:${BUILD_NUMBER}
                        echo "✅ Rollback completed."
                    else
                        echo "⚠️ No backup found."
                    fi
                '
            """
        }
        success {
            echo "✅ Deployment completed successfully!"
        }
    }
}
