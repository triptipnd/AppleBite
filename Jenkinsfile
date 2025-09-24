pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "myphpapp:latest"
        DOCKER_CONTAINER = "php-webapp"
        SERVER_IP = "172.18.54.197"  // replace with your Test Server/Slave IP
        SSH_USER = "jenkins"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/triptipnd/AppleBite.git'
            }
        }

        stage('Install Docker on Test Server via Ansible') {
            steps {
                sh '''
                ansible-playbook -i ${SERVER_IP}, ansible/install-docker.yml \
                  --user=${SSH_USER}
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }

        stage('Deploy to Test Server') {
            steps {
                sh '''
                ssh ${SSH_USER}@${SERVER_IP} "docker rm -f ${DOCKER_CONTAINER} || true"
                ssh ${SSH_USER}@${SERVER_IP} "docker run -d -p 80:80 --name ${DOCKER_CONTAINER} ${DOCKER_IMAGE}"
                '''
            }
        }
    }

    post {
        failure {
            echo "Build/Deployment failed. Cleaning up..."
            sh '''
            ssh ${SSH_USER}@${SERVER_IP} "docker rm -f ${DOCKER_CONTAINER} || true"
            '''
        }
    }
}
