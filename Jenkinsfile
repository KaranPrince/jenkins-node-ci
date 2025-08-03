pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/KaranPrince/jenkins-node-ci.git'
      }
    }

    stage('Install Dependencies') {
      steps {
        sh 'npm install'
      }
    }

    stage('Test') {
      steps {
        sh 'npm test'
      }
    }

    stage('Build Success') {
      steps {
        echo 'Build and Test Successful!'
      }
    }
  }
}
