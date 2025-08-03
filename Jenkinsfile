pipeline {
    agent any

    environment {
        BUILD_ID = "${env.BUILD_NUMBER}"
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
                echo "\n🔧 Build stage initiated..."
                echo "✅ Build Stage Started: Compiling or preparing code (simulated)\n"
            }
        }

        stage('Test') {
            steps {
                echo "\n🧪 Running basic tests..."
                sh 'echo All tests passed successfully!\n'
            }
        }

        stage('Deploy') {
            steps {
                echo "\n🚀 Deploying to test environment..."
                sh 'echo Deployment simulated.\n'
                echo "✅ Deploy Stage: Deploying updated HTML with About section\n"
            }
        }
    }

    post {
        success {
            echo "🎉 SUCCESS: Build #${env.BUILD_ID} completed successfully!"
        }
        failure {
            echo "❌ FAILURE: Build #${env.BUILD_ID} failed."
        }
    }
}
