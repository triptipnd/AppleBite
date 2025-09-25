pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t myphpapp:latest .'
            }
        }

        stage('Deploy to Test Server') {
            steps {
                sh 'ssh jenkins@172.18.54.197 docker rm -f php-webapp || true'
                sh 'ssh jenkins@172.18.54.197 docker run -d -p 80:80 --name php-webapp myphpapp:latest'
            }
        }
    }
}
