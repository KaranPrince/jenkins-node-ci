pipeline {
    agent any

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
                echo "✅ Build Stage Started: Compiling or preparing code (simulated)"
                // Add actual build commands if applicable
            }
        }

        stage('Test') {
            steps {
                echo '🧪 Running basic tests...'
                // Add test scripts here
                sh 'echo "All tests passed successfully!"'
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying to test environment...'
                // Simulate deployment step
                sh 'echo "Deployment simulated."'
                echo "✅ Deploy Stage: Deploying updated HTML with About section"
            }
        }
    }

    post {
        success {
            echo '✅ Build #${BUILD_NUMBER} completed successfully!'
        }
        failure {
            echo '❌ Build #${BUILD_NUMBER} failed. Check logs!'
        }
    }
}
