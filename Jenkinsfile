pipeline {
    agent any

    environment {
        TEST_SERVER = '172.18.54.197'
        PROD_SERVER = ' 172.17.0.1' // replace with actual PROD server IP
        IMAGE_NAME  = 'myphpapp:latest'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout([$class: 'GitSCM', 
                    branches: [[name: 'main']], 
                    userRemoteConfigs: [[url: 'https://github.com/triptipnd/AppleBite.git']]])
            }
        }

        stage('Job 1 - Install Puppet Agent') {
            steps {
                echo "Installing puppet agent on test server..."
                sh "ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} sudo apt-get update && sudo apt-get install -y puppet-agent || true"
            }
        }

        stage('Job 2 - Install Docker via Ansible') {
            steps {
                echo "[testserver]\n${TEST_SERVER} ansible_user=jenkins ansible_ssh_common_args='-o StrictHostKeyChecking=no'" > inventory_test
                sh "ansible-playbook -i inventory_test ansible/install-docker.yml --ssh-extra-args='-o StrictHostKeyChecking=no'"
            }
        }

        stage('Job 3 - Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Job 4 - Deploy to Test Server') {
            steps {
                echo "Deploying Docker image to TEST server..."
                sh """
                    ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker rm -f php-webapp || true
                    docker save ${IMAGE_NAME} | bzip2 | ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} 'bunzip2 | docker load'
                    ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker run -d -p 80:80 --name php-webapp ${IMAGE_NAME}
                """
            }
        }

        stage('Job 5 - Deploy to Prod Server') {
            steps {
                script {
                    if (env.PROD_SERVER?.trim()) {
                        echo "Deploying to PROD server: ${env.PROD_SERVER}"
                        sh """
                            ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker rm -f php-webapp || true
                            docker save ${IMAGE_NAME} | bzip2 | ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} 'bunzip2 | docker load'
                            ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker run -d -p 80:80 --name php-webapp ${IMAGE_NAME}
                        """
                    } else {
                        echo "PROD_SERVER variable not set. Skipping PROD deployment."
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up test/prod containers..."
            sh "ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker rm -f php-webapp || true"
            if (env.PROD_SERVER?.trim()) {
                sh "ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker rm -f php-webapp || true"
            }
        }
        failure {
            echo "Pipeline failed!"
        }
        success {
            echo "Pipeline completed successfully!"
        }
    }
}

