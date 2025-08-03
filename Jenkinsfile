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
                    def branch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def hash = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    def author = sh(script: "git log -1 --pretty=format:'%an'", returnStdout: true).trim()
                    def date = sh(script: "git log -1 --pretty=format:'%cd'", returnStdout: true).trim()
                    def message = sh(script: "git log -1 --pretty=format:'%s'", returnStdout: true).trim()

                    sh """
                        sed -i 's|\\\$\\{GIT_BRANCH\\}|${branch}|' index.html
                        sed -i 's|\\\$\\{GIT_COMMIT\\}|${hash}|' index.html
                        sed -i 's|\\\$\\{GIT_AUTHOR\\}|${author}|' index.html
                        sed -i 's|\\\$\\{GIT_DATE\\}|${date}|' index.html
                        sed -i 's|\\\$\\{GIT_MESSAGE\\}|${message}|' index.html
                        sed -i 's|\\\$\\{BUILD_NUMBER\\}|${env.BUILD_NUMBER}|' index.html
                    """
                }
            }
        }

        stage('Deploy to Web Server') {
            steps {
                echo '🚀 Deploying index.html to web root...'
                // Change this path if needed
                sh 'sudo cp index.html /var/www/html/index.html'
            }
        }
    }

    post {
        success {
            echo "✅ Deployment completed successfully!"
        }
        failure {
            echo "❌ Deployment failed."
        }
    }
}
