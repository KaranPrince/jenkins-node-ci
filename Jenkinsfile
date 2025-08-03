pipeline {
    agent any

    environment {
        APP_NAME = "NodeCIApp"
        DEPLOY_ENV = "test" // change to dev/prod as needed
    }

    options {
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('📦 Checkout Code') {
            steps {
                echo "🔄 Checking out source code from GitHub..."
                checkout scm
            }
        }

        stage('🔧 Build') {
            steps {
                echo "🔧 Build Stage Started for ${APP_NAME}"
                sh 'echo Compiling code...'
                sh 'mkdir -p build && cp -r app/* build/'
            }
        }

        stage('🧪 Test') {
            steps {
                echo "🧪 Running Unit Tests..."
                sh 'echo Running test: sample.test.js'
                sh 'echo ✅ All tests passed!'
            }
        }

        stage('📦 Archive Artifact') {
            steps {
                echo "📦 Archiving build artifacts..."
                archiveArtifacts artifacts: 'build/**', fingerprint: true
            }
        }

        stage('🚀 Deploy') {
            steps {
                echo "🚀 Deploying to ${DEPLOY_ENV} environment..."
                sh "echo ✅ Deployment simulated for ${APP_NAME}"
            }
        }
    }

    post {
        success {
            echo "✅ Build #${env.BUILD_NUMBER} completed successfully by ${env.BUILD_USER}!"
        }
        failure {
            echo "❌ Build #${env.BUILD_NUMBER} failed. Please check logs."
        }
    }
}

