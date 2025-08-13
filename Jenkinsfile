pipeline {
    agent any

    environment {
        DEPLOY_USER  = 'ubuntu'
        DEPLOY_HOST  = '44.222.203.180'
        PEM_KEY_PATH = '/var/lib/jenkins/karan.pem'
        BUILD_TIME   = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
    }

    stages {

        stage('Checkout Source') {
            steps {
                echo "📥 Pulling latest source code from GitHub..."
                checkout scm
            }
        }

        stage('Validate HTML') {
            steps {
                echo "🔍 Validating HTML syntax..."
                sh '''
                    set -e
                    command -v tidy &>/dev/null || (sudo apt-get update && sudo apt-get install -y tidy)
                    tidy -qe app/index.html
                '''
            }
        }

        stage('Inject Build Metadata') {
            steps {
                echo "📝 Injecting build & Git metadata..."
                script {
                    def branch = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def commit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    def author = sh(script: "git log -1 --pretty=format:%an", returnStdout: true).trim()
                    def msg    = sh(script: "git log -1 --pretty=format:%s", returnStdout: true).trim()

                    sh """
                        sed -i "s|__BUILD_NUMBER__|${env.BUILD_NUMBER}|g" app/index.html
                        sed -i "s|__GIT_BRANCH__|${branch}|g" app/index.html
                        sed -i "s|__GIT_COMMIT__|${commit}|g" app/index.html
                        sed -i "s|__GIT_AUTHOR__|${author}|g" app/index.html
                        sed -i "s|__GIT_DATE__|${BUILD_TIME}|g" app/index.html
                        sed -i "s|__GIT_MESSAGE__|${msg}|g" app/index.html
                    """
                }
            }
        }

        stage('Package Artifact') {
            steps {
                echo "📦 Packaging application..."
                sh 'tar -czf deploy_artifact.tar.gz app/'
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo "🚀 Deploying to EC2..."
                sh '''
                    set -e
                    PEM=${PEM_KEY_PATH}
                    USER=${DEPLOY_USER}
                    HOST=${DEPLOY_HOST}

                    deploy_dir=/var/www/html/jenkins-deploy
                    backup_file=/tmp/rollback_backup.tar.gz
                    artifact=/tmp/deploy_artifact.tar.gz

                    echo "💾 Creating backup if deployment exists..."
                    ssh -i $PEM -o StrictHostKeyChecking=no $USER@$HOST '
                        if [ -d $deploy_dir ]; then
                            sudo tar -czf $backup_file -C /var/www/html jenkins-deploy
                        fi
                    '

                    echo "📤 Copying artifact..."
                    scp -i $PEM -o StrictHostKeyChecking=no deploy_artifact.tar.gz $USER@$HOST:/tmp/

                    echo "⚙️ Deploying..."
                    ssh -i $PEM -o StrictHostKeyChecking=no $USER@$HOST '
                        sudo mkdir -p $deploy_dir &&
                        sudo tar -xzf $artifact -C $deploy_dir --strip-components=1 &&
                        sudo rm $artifact &&
                        sudo systemctl restart apache2
                    '

                    echo "🔍 Verifying deployment..."
                    STATUS=$(curl -o /dev/null -s -w "%{http_code}" http://$HOST/jenkins-deploy/)
                    if [ "$STATUS" -ne 200 ]; then
                        echo "❌ Deployment failed!"
                        exit 1
                    fi
                    echo "✅ Deployment successful."
                '''
            }
        }
    }

    post {
        failure {
            echo "♻️ Rolling back to previous version..."
            sh '''
                PEM=${PEM_KEY_PATH}
                USER=${DEPLOY_USER}
                HOST=${DEPLOY_HOST}
                backup_file=/tmp/rollback_backup.tar.gz
                deploy_dir=/var/www/html/jenkins-deploy

                ssh -i $PEM -o StrictHostKeyChecking=no $USER@$HOST '
                    if [ -f $backup_file ]; then
                        sudo rm -rf $deploy_dir &&
                        sudo tar -xzf $backup_file -C /var/www/html &&
                        sudo systemctl restart apache2
                        echo "✅ Rollback completed."
                    else
                        echo "⚠️ No rollback backup found!"
                    fi
                '
            '''
        }
        success {
            echo "🎉 Deployment pipeline finished successfully."
        }
    }
}
