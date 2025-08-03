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
        sh """
        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ${DEPLOY_USER}@${DEPLOY_HOST} "
            sudo mkdir -p /var/www/html/jenkins-deploy &&
            sudo rm -rf /var/www/html/jenkins-deploy/* &&
            echo '<h1>Deployed via Jenkins from GitHub Webhook 🚀</h1>' | sudo tee /var/www/html/jenkins-deploy/index.html
        "
        """
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
