pipeline {
    agent any

    environment {
        DEPLOY_DIR = "/var/www/html/jenkins-deploy"
        BACKUP_FILE = "/tmp/rollback_backup.tar.gz"
        EC2_USER = "ubuntu"
        EC2_HOST = "54.90.221.101" // Update to your current EC2 public IP
        PEM = "/var/lib/jenkins/karan.pem"
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/KaranPrince/jenkins-node-ci.git', branch: 'master'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test'
            }
        }

        stage('Inject Metadata') {
            steps {
                script {
                    def dateStr = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
                    sh """
                        sed -i 's|__BUILD_NUMBER__|${BUILD_NUMBER}|g' app/index.html
                        sed -i 's|__GIT_DATE__|${dateStr}|g' app/index.html
                        sed -i 's|__GIT_BRANCH__|${env.GIT_BRANCH}|g' app/index.html
                        sed -i 's|__GIT_COMMIT__|${sh(script: "git rev-parse HEAD", returnStdout: true).trim()}|g' app/index.html
                        sed -i 's|__GIT_AUTHOR__|${sh(script: "git log -1 --pretty=format:%an", returnStdout: true).trim()}|g' app/index.html
                        sed -i 's|__GIT_MESSAGE__|${sh(script: "git log -1 --pretty=format:%s", returnStdout: true).trim()}|g' app/index.html
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t jenkins_node_app:${BUILD_NUMBER} ."
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    // Backup existing container if exists
                    sh """
                    ssh -i ${PEM} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                        sudo mkdir -p ${DEPLOY_DIR}
                        if sudo docker ps -q -f name=jenkins_node_app >/dev/null 2>&1; then
                            sudo docker commit jenkins_node_app backup_jenkins_node_app:${BUILD_NUMBER}
                            sudo docker save -o ${BACKUP_FILE} backup_jenkins_node_app:${BUILD_NUMBER}
                            sudo docker rm -f jenkins_node_app
                        fi
                    '
                    """

                    // Copy project files to EC2
                    sh "scp -i ${PEM} -r ./app ${EC2_USER}@${EC2_HOST}:${DEPLOY_DIR}/"

                    // Run Docker container
                    sh """
                    ssh -i ${PEM} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                        cd ${DEPLOY_DIR}
                        docker build -t jenkins_node_app:${BUILD_NUMBER} .
                        docker run -d --name jenkins_node_app -p 80:80 jenkins_node_app:${BUILD_NUMBER}
                    '
                    """
                }
            }
        }
    }

    post {
        failure {
            echo '⚠️ Deployment failed, rolling back...'
            sh """
            ssh -i ${PEM} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} '
                if [ -f ${BACKUP_FILE} ]; then
                    sudo docker load -i ${BACKUP_FILE}
                    sudo docker rm -f jenkins_node_app || true
                    sudo docker run -d --name jenkins_node_app -p 80:80 backup_jenkins_node_app:${BUILD_NUMBER}
                    echo "✅ Rollback completed."
                else
                    echo "⚠️ No backup found to restore."
                fi
            '
            """
        }
    }
}
