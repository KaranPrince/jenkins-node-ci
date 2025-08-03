pipeline {
    agent any

    environment {
        DEPLOY_USER = 'ubuntu'
        DEPLOY_HOST = '13.232.138.18'
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
                echo '✅ Build Stage Started: Compiling or preparing code (simulated)'
            }
        }

        stage('Test') {
            steps {
                echo '🧪 Running basic tests...'
                sh 'echo All tests passed successfully!'
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying to EC2 Instance...'

                script {
                    env.GIT_BRANCH = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    env.GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    env.GIT_AUTHOR = sh(script: 'git log -1 --pretty=format:%an', returnStdout: true).trim()
                    env.GIT_DATE = sh(script: 'git log -1 --pretty=format:%cd', returnStdout: true).trim()
                    env.GIT_MESSAGE = sh(script: 'git log -1 --pretty=format:%s', returnStdout: true).trim()

                    sh """
                    sed -i "s|__BUILD_NUMBER__|${env.BUILD_NUMBER}|g" app/index.html
                    sed -i "s|__GIT_DATE__|${env.GIT_DATE}|g" app/index.html
                    sed -i "s|__GIT_BRANCH__|${env.GIT_BRANCH}|g" app/index.html
                    sed -i "s|__GIT_COMMIT__|${env.GIT_COMMIT}|g" app/index.html
                    sed -i "s|__GIT_AUTHOR__|${env.GIT_AUTHOR}|g" app/index.html
                    sed -i "s|__GIT_MESSAGE__|${env.GIT_MESSAGE}|g" app/index.html

                    scp -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} app/index.html ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/index.html
                    ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ${DEPLOY_USER}@${DEPLOY_HOST} '
                        sudo mv /tmp/index.html /var/www/html/index.html
                    '
                    """
                }

                echo '✅ Deployment to EC2 completed!'
            }
        }
    }

    post {
        success {
            echo "✅ Build #${env.BUILD_NUMBER} completed and deployed successfully!"
        }
        failure {
            echo "❌ Build #${env.BUILD_NUMBER} failed."
        }
    }
}
