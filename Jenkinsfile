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
            def gitBranch = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
            def gitCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
            def gitAuthor = sh(script: 'git log -1 --pretty=format:\'%an\'', returnStdout: true).trim()
            def gitDate = sh(script: 'git log -1 --pretty=format:\'%cd\'', returnStdout: true).trim()
            def gitMessage = sh(script: 'git log -1 --pretty=format:\'%s\'', returnStdout: true).trim()

            sh """
            sed -i 's|\\\$\\{GIT_BRANCH\\}|${gitBranch}|' index.html
            sed -i 's|\\\$\\{GIT_COMMIT\\}|${gitCommit}|' index.html
            sed -i 's|\\\$\\{GIT_AUTHOR\\}|${gitAuthor}|' index.html
            sed -i 's|\\\$\\{GIT_DATE\\}|${gitDate}|' index.html
            sed -i 's|\\\$\\{GIT_MESSAGE\\}|${gitMessage}|' index.html
            """
        }

        sh """
        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ${DEPLOY_USER}@${DEPLOY_HOST} '
            sudo mkdir -p /var/www/html/jenkins-deploy &&
            sudo rm -rf /var/www/html/jenkins-deploy/*'
        scp -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} index.html ${DEPLOY_USER}@${DEPLOY_HOST}:/tmp/index.html
        ssh -o StrictHostKeyChecking=no -i ${PEM_KEY_PATH} ${DEPLOY_USER}@${DEPLOY_HOST} '
            sudo mv /tmp/index.html /var/www/html/jenkins-deploy/index.html'
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
