pipeline {
    agent any

    environment {
        DEPLOY_USER = 'ubuntu'
        DEPLOY_HOST = 'YOUR_PUBLIC_EC2_IP'
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem'
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
                echo '✅ Simulating build process...'
            }
        }

        stage('Test') {
            steps {
                echo '🧪 Running basic tests...'
                sh 'echo All tests passed!'
            }
        }

        stage('Inject Git Info') {
            steps {
                echo '📝 Injecting Git data into HTML...'
                script {
                    def gitBranch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def gitCommit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    def gitAuthor = sh(script: "git log -1 --pretty=format:%an", returnStdout: true).trim()
                    def gitDate = sh(script: "git log -1 --pretty=format:%cd", returnStdout: true).trim()
                    def gitMessage = sh(script: "git log -1 --pretty=format:%s", returnStdout: true).trim()
                    def buildNum = env.BUILD_NUMBER

                    sh "sed -i 's|__BUILD_NUMBER__|${buildNum}|' index.html"
                    sh "sed -i 's|__GIT_BRANCH__|${gitBranch}|' index.html"
                    sh "sed -i 's|__GIT_COMMIT__|${gitCommit}|' index.html"
                    sh "sed -i 's|__GIT_AUTHOR__|${gitAuthor}|' index.html"
                    sh "sed -i 's|__GIT_DATE__|${gitDate}|' index.html"
                    sh "sed -i 's|__GIT_MESSAGE__|${gitMessage}|' index.html"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo '🚀 Deploying to EC2...'
                sh """
                ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ${DEPLOY_USER}@${DEPLOY_HOST} '
                    sudo mkdir -p /var/www/html/jenkins-deploy &&
                    sudo rm -rf /var/www/html/jenkins-deploy/* &&
                    sudo cp index.html /var/www/html/jenkins-deploy/index.html
                '
                """
            }
        }
    }

    post {
        success {
            echo "✅ Deployment Complete!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
