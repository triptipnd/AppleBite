pipeline {
    agent any

    environment {
        TEST_SERVER = "172.18.54.197"
        PROD_SERVER = "${env.PROD_SERVER}"  // Uses Jenkins build parameter
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Install Puppet Agent on Test Server') {
            steps {
                sh """
                echo "Installing puppet agent on test server..."
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} sudo apt-get update
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} sudo apt-get install -y puppet-agent || true
                """
            }
        }

		stage('Install Docker via Ansible on Test Server') {
			    steps {
			        sh """
			        echo "[testserver]" > inventory_test
			        echo "${TEST_SERVER} ansible_user=jenkins ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory_test

			        # Disable SSH host key checking globally for this run
			        export ANSIBLE_HOST_KEY_CHECKING=False

			        # Run the Ansible playbook
			        ansible-playbook -i inventory_test ansible/install-docker.yml
			        """
			    }
			}



        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t myphpapp:latest .
                """
            }
        }

        stage('Deploy to Test Server') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker rm -f php-webapp || true
                docker save myphpapp:latest | ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker load
                ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker run -d -p 80:80 --name php-webapp myphpapp:latest
                """
            }
        }

        stage('Deploy to Prod Server') {
            when {
                expression { return PROD_SERVER?.trim() }  // Only run if PROD_SERVER is set
            }
            steps {
                sh """
                echo "Deploying to PROD server: ${PROD_SERVER}"
                ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker rm -f php-webapp || true
                docker save myphpapp:latest | ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker load
                ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker run -d -p 80:80 --name php-webapp myphpapp:latest
                """
            }
        }
    }

# post {
 #       always {
  #          sh """
   #         echo "Cleaning up containers..."
    #        ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} docker rm -f php-webapp || true
     #       if [ -n "${PROD_SERVER}" ]; then
      #          ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} docker rm -f php-webapp || true
       #     fi
        #    """
        #}
    #}
#}

post {
    always {
        sh """
        echo "Cleaning up containers..."
        # Remove stopped containers on Test Server
        ssh -o StrictHostKeyChecking=no jenkins@${TEST_SERVER} 'docker container prune -f'
        
        # Remove stopped containers on Prod Server, if defined
        if [ -n "${PROD_SERVER}" ]; then
            ssh -o StrictHostKeyChecking=no jenkins@${PROD_SERVER} 'docker container prune -f'
        fi
        """
    }
}
