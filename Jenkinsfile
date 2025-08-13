stage('Deploy to EC2') {
    steps {
        echo "Deploying to EC2 instance..."
        script {
            def EC2_PRIVATE_IP = "10.0.1.192" // Web server private IP

            // Generate and copy ECR login token to target server
            sh """
                set -e
                ECR_TOKEN_FILE=/tmp/ecr_token.txt
                aws ecr get-login-password --region us-east-1 > \$ECR_TOKEN_FILE
                scp -o StrictHostKeyChecking=no -i /var/lib/jenkins/karan.pem \$ECR_TOKEN_FILE ubuntu@${EC2_PRIVATE_IP}:/tmp/ecr_token.txt
            """

            // SSH into server and pull + run the container
            sh """
                ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/karan.pem ubuntu@${EC2_PRIVATE_IP} '
                cat /tmp/ecr_token.txt | docker login --username AWS --password-stdin 576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app &&
                docker pull 576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app:latest &&
                docker stop app || true &&
                docker rm app || true &&
                docker run -d --name app -p 80:3000 576290270995.dkr.ecr.us-east-1.amazonaws.com/my-node-app:latest
                '
            """
        }
    }
}
