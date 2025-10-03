pipeline {
    agent any

    environment {
        TEST_SERVER = "172.18.54.197"
        PROD_SERVER = "${env.PROD_SERVER}"  // Pass PROD_SERVER as a parameter in Jenkins if available
        IMAGE_NAME = "myphpapp:latest"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git url: 'https://github.com/triptipnd/AppleBite.git', branch: 'main', credentialsId: 'fc3904a9-0596-477b-95e5-e29e8c568db4'
            }
        }

        stage('Install Puppet Agent') {
            steps {
                sh """
                echo Installing puppet agent on test server...
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} sudo apt-get update && sudo apt-get install -y puppet-agent || true
                """
            }
        }

        stage('Install Docker via Ansible') {
            steps {
                sh """
                echo "[testserver]\\n${TEST_SERVER} ansible_user=jenkins ansible_ssh_common_args='-o StrictHostKeyChecking=no'" > inventory_test
                ansible-playbook -i inventory_test ansible/install-docker.yml --ssh-extra-args='-o StrictHostKeyChecking=no'
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${IMAGE_NAME} .
                """
            }
        }

        stage('Deploy to Test Server') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker rm -f php-webapp || true
                docker save ${IMAGE_NAME} | ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} 'docker load'
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker run -d -p 80:80 --name php-webapp ${IMAGE_NAME}
                """
            }
        }

        stage('Deploy to Prod Server') {
            when {
                expression { return env.PROD_SERVER?.trim() }
            }
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker rm -f php-webapp || true
                docker save ${IMAGE_NAME} | ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} 'docker load'
                ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker run -d -p 80:80 --name php-webapp ${IMAGE_NAME}
                """
            }
        }
    }

    post {
        failure {
            sh """
            echo Pipeline failed — cleaning up containers...
            ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker rm -f php-webapp || true
            if [ -n "${PROD_SERVER}" ]; then
                ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker rm -f php-webapp || true
            fi
            """
        }
    }
}
