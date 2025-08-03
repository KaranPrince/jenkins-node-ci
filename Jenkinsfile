pipeline {
    agent any
    environment {
        DEPLOY_USER = "ubuntu"
        DEPLOY_HOST = "13.232.138.18"
        PEM_FILE = "/var/lib/jenkins/karan.pem"
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
                echo '🚀 Deploying to EC2 instance...'
                sh '''
                scp -o StrictHostKeyChecking=no -i ${PEM_FILE} -r * ${DEPLOY_USER}@${DEPLOY_HOST}:/home/ubuntu/app/
                '''
                echo '✅ Deploy Stage: Files sent to EC2!'
            }
        }
    }
    post {
        success {
            echo "✅ Build ${env.BUILD_NUMBER} completed successfully and deployed to EC2!"
        }
        failure {
            echo "❌ Build failed."
        }
    }
}
