# Jenkins Node.js CI/CD Pipeline 🚀

This project demonstrates a complete CI/CD pipeline using **Jenkins**, triggered by GitHub Webhook and deployed to an **EC2 Ubuntu server**. It is designed as a beginner-friendly but industry-ready DevOps showcase.

---

## 🔧 Tech Stack

- **Version Control**: Git & GitHub
- **CI/CD Tool**: Jenkins (Declarative Pipeline)
- **Cloud**: AWS EC2 (Ubuntu)
- **Scripting**: Shell
- **OS**: Linux (Ubuntu 22.04)
- **Language**: Node.js (simulated project)

---

## ✅ CI/CD Workflow Overview

### 1️⃣ **Trigger**
- Webhook triggers Jenkins on every push to `master` branch.

### 2️⃣ **Pipeline Stages**
- `Checkout`: Pull latest code from GitHub
- `Build`: Simulate code compilation/building
- `Test`: Run test stage (`echo "All tests passed"`)
- `Deploy`: Copy final files to EC2 instance using `scp` and `pem` authentication

### 3️⃣ **Post-Build**
- Custom console logs for easy debugging & tracking
- Dynamic `BUILD_NUMBER` for traceability

---

## 📂 Jenkinsfile

```groovy
pipeline {
    agent any
    environment {
        DEPLOY_USER = 'ubuntu'
        DEPLOY_HOST = 'YOUR_EC2_PUBLIC_IP'
        PEM_FILE = '/var/lib/jenkins/jenkins-key.pem'
    }
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checking out source code...'
                checkout scm
            }
        }
        stage('Build') {
            steps {
                echo '🔧 Build stage initiated...'
                echo '✅ Build successful!'
            }
        }
        stage('Test') {
            steps {
                echo '🧪 Running tests...'
                sh 'echo All tests passed successfully!'
            }
        }
        stage('Deploy') {
            steps {
                echo '🚀 Deploying to EC2...'
                sh '''
                scp -o StrictHostKeyChecking=no -i $PEM_FILE index.html $DEPLOY_USER@$DEPLOY_HOST:/var/www/html/index.html
                '''
                echo "✅ Build #${BUILD_NUMBER} deployed to EC2: http://${DEPLOY_HOST}"
            }
        }
    }
    post {
        success {
            echo "✅ Build #${BUILD_NUMBER} completed successfully!"
        }
        failure {
            echo "❌ Build failed. Check logs for details."
        }
    }
}

# Webhook Test

✅ This commit is used to trigger Jenkins via GitHub Webhook!

# Webhook Trigger Confirmation

✅ Webhook Triggering the Jenkins pipeline...


