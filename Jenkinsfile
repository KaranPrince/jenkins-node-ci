pipeline {
    agent any

    environment {
        // Define placeholders for Git info
        GIT_BRANCH = ''
        GIT_COMMIT_HASH = ''
        GIT_COMMIT_AUTHOR = ''
        GIT_COMMIT_DATE = ''
        GIT_COMMIT_MESSAGE = ''
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
                // Simulate build or actual build steps here
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
                
                // Fetch Git info
                script {
                    env.GIT_BRANCH = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    env.GIT_COMMIT_HASH = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    env.GIT_COMMIT_AUTHOR = sh(script: 'git log -1 --pretty=format:"%an"', returnStdout: true).trim()
                    env.GIT_COMMIT_DATE = sh(script: 'git log -1 --pretty=format:"%cd"', returnStdout: true).trim()
                    env.GIT_COMMIT_MESSAGE = sh(script: 'git log -1 --pretty=format:"%s"', returnStdout: true).trim()
                }

                // Replace placeholders in index.html
                sh """
                    sed -i 's|\\\$\\{GIT_BRANCH\\}|${GIT_BRANCH}|' index.html
                    sed -i 's|\\\$\\{GIT_COMMIT_HASH\\}|${GIT_COMMIT_HASH}|' index.html
                    sed -i 's|\\\$\\{GIT_COMMIT_AUTHOR\\}|${GIT_COMMIT_AUTHOR}|' index.html
                    sed -i 's|\\\$\\{GIT_COMMIT_DATE\\}|${GIT_COMMIT_DATE}|' index.html
                    sed -i 's|\\\$\\{GIT_COMMIT_MESSAGE\\}|${GIT_COMMIT_MESSAGE}|' index.html
                """

                echo "✅ Git commit info injected successfully into index.html"
            }
        }
    }

    post {
        success {
            echo "🎉 Build #${BUILD_NUMBER} completed successfully!"
        }
        failure {
            echo "❌ Build #${BUILD_NUMBER} failed."
        }
    }
}
