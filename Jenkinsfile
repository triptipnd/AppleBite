pipeline {
    agent any

    environment {
        SSH_CRED_ID   = 'jenkins-ssh'
        TEST_SERVER   = '172.18.54.197'
        PROD_SERVER   = "${env.PROD_SERVER}"
        IMAGE_NAME    = "myphpapp:latest"
        CONTAINER_NAME = "php-webapp"
        GIT_REPO      = 'https://github.com/triptipnd/AppleBite.git'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GIT_REPO}"
            }
        }

        stage('Job 1 - Install Puppet Agent') {
            steps {
                sh '''
                echo "Installing puppet agent on test server..."
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} \
                  "sudo apt-get update && sudo apt-get install -y puppet-agent || true"
                '''
            }
        }

        stage('Job 2 - Install Docker via Ansible') {
            steps {
                sh '''
                echo "[testserver]
                ${TEST_SERVER} ansible_user=jenkins ansible_ssh_common_args='-o StrictHostKeyChecking=no'" > inventory_test

                ansible-playbook -i inventory_test ansible/install-docker.yml --ssh-extra-args='-o StrictHostKeyChecking=no'
                '''
            }
        }

        stage('Job 3 - Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Job 4 - Deploy to Test Server') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} "docker rm -f ${CONTAINER_NAME} || true"
                docker save ${IMAGE_NAME} | bzip2 | ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} 'bunzip2 | docker load'
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} "docker run -d -p 80:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}"
                """
            }
        }

        stage('Job 5 - Deploy to Prod Server') {
            when {
                expression { return env.PROD_SERVER && env.PROD_SERVER.trim() != "" }
            }
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} "docker rm -f ${CONTAINER_NAME} || true"
                docker save ${IMAGE_NAME} | bzip2 | ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} 'bunzip2 | docker load'
                ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} "docker run -d -p 80:80 --name ${CONTAINER_NAME} ${IMAGE_NAME}"
                """
            }
        }
    }

    post {
        failure {
            sh """
            echo "Pipeline failed — cleaning up test/prod containers."
            ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} "docker rm -f ${CONTAINER_NAME} || true"
            if [ -n "${PROD_SERVER}" ]; then
              ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} "docker rm -f ${CONTAINER_NAME} || true"
            fi
            """
        }
    }
}
