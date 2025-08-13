pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        ECR_REPO = "123456789012.dkr.ecr.us-east-1.amazonaws.com/your-repo"
        PEM_KEY = "/var/lib/jenkins/karan.pem"
        REMOTE_HOST = "54.90.221.101"
        REMOTE_USER = "ubuntu"
        APP_DIR = "/home/ubuntu/app"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/KaranPrince/jenkins-node-ci.git'
            }
        }

        stage('AWS ECR Login Token') {
            steps {
                script {
                    GIT_DATE = sh(script: "date '+%Y-%m-%d %H:%M:%S'", returnStdout: true).trim()
                    ECR_TOKEN_FILE = "/tmp/ecr_token_${BUILD_NUMBER}.txt"
                    sh """
                        aws ecr get-login-password --region $AWS_REGION > ${ECR_TOKEN_FILE}
                        scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $PEM_KEY ${ECR_TOKEN_FILE} ${REMOTE_USER}@${REMOTE_HOST}:/tmp/ecr_token.txt
                    """
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                sh """
                    cd ${WORKSPACE}  # Ensure we are in repo root
                    if [ ! -f Dockerfile ]; then
                        echo "❌ Dockerfile not found!"
                        exit 1
                    fi
                    docker build -t $ECR_REPO:latest .
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                    docker push $ECR_REPO:latest
                """
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh """
                    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $PEM_KEY ${REMOTE_USER}@${REMOTE_HOST} '
                        mkdir -p $APP_DIR &&
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO &&
                        docker pull $ECR_REPO:latest &&
                        docker stop myapp || true &&
                        docker rm myapp || true &&
                        docker run -d --name myapp -p 80:3000 $ECR_REPO:latest
                    '
                """
            }
        }
    }

    post {
        always {
            sh "docker system prune -af"
        }
    }
}
