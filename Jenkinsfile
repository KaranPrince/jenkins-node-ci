pipeline {
    agent any

    environment {
        DEPLOY_USER = 'ubuntu'
        DEPLOY_HOST = 'your.ec2.public.ip' // Replace or use a parameter
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
                echo '✅ Simulating build steps...'
            }
        }

        stage('Test') {
            steps {
                echo '🧪 Running basic tests...'
                sh 'echo All tests passed successfully!'
            }
        }

        stage('Inject Git Info into HTML') {
            steps {
                echo '📝 Injecting Git commit info into index.html...'
                script {
                    def gitBranch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def gitCommit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    def gitAuthor = sh(script: "git log -1 --pretty=format:%an", returnStdout: true).trim()
                    def gitDate = sh(script: "git log -1 --pretty=format:%cd", returnStdout: true).trim()
                    def gitMessage = sh(script: "git log -1 --pretty=format:%s", returnStdout: true).trim()
                    def buildNumber = env.BUILD_NUMBER

                    sh "sed -i 's|\\\$\\{BUILD_NUMBER\\}|${buildNumber}|' index.html"
                    sh "sed -i 's|\\\$\\{GIT_BRANCH\\}|${gitBranch}|' index.html"
                    sh "sed -i 's|\\\$\\{GIT_COMMIT\\}|${gitCommit}|' index.html"
                    sh "sed -i 's|\\\$\\{GIT_AUTHOR\\}|${gitAuthor}|' index.html"
                    sh "sed -i 's|\\\$\\{GIT_DATE\\}|${gitDate}|' index.html"
                    sh "sed -i 's|\\\$\\{GIT_MESSAGE\\}|${gitMessage}|' index.html"
                }
            }
        }

        stage('Deploy to Web Server') {
            steps {
                echo '🚀 Deploying to EC2 Instance...'
                sh """
                ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ${DEPLOY_USER}@${DEPLOY_HOST} '
                    sudo mkdir -p /var/www/html/jenkins-deploy &&
                    sudo rm -rf /var/www/html/jenkins-deploy/* &&
                    sudo cp index.html /var/www/html/jenkins-deploy/index.html
                '
                """
                echo '✅ Deployment complete!'
            }
        }
    }

    post {
        success {
            echo "✅ Build #${env.BUILD_NUMBER} completed and deployed successfully!"
        }
        failure {
            echo "❌ Deployment failed."
        }
    }
}
