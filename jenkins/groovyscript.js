pipeline {
    agent any

    parameters {
        string(name: 'NAMESPACE', defaultValue: 'default', description: 'Kubernetes namespace to apply the config')
        //base64File(name: 'KUBE_CONFIG', description: 'Upload Kubernetes config file for cluster access')
        // getting the stored  jenkins credentials
        credentials(name: 'KUBECONFIG_CREDENTIAL_ID', description: 'Select the kubeconfig credential to use', required: true, credentialType: 'Secret file')
        
        base64File(name: 'SECRETS_YAML', description: 'Upload Secrets.yaml file to apply to the cluster')
    }

    environment {
        DOCKER_IMAGE = 'dind-kube:latest'
    }

    stages {
        stage('Diagnose Parameters') {
            steps {
                script {
                    echo "Namespace: ${params.NAMESPACE}"
                    echo "KUBECONFIG_CREDENTIAL_ID provided: ${params.KUBECONFIG_CREDENTIAL_ID ? 'Yes' : 'No'}"
                    echo "SECRETS_YAML provided: ${params.SECRETS_YAML ? 'Yes' : 'No'}"
                    
                    echo "Workspace contents:"
                    sh 'ls -la ${WORKSPACE}'
                    
                    echo "All environment variables:"
                    sh 'env | sort'
                }
            }
        }

        stage('Prepare Files') {
            steps {
                script {
                    // Create temporary directory
                    sh 'mkdir -p /tmp/jenkins-k8s-apply'

                    // // Decode and save KUBE_CONFIG
                    // if (params.KUBE_CONFIG) {
                    //     writeFile file: '/tmp/jenkins-k8s-apply/kubeconfig', text: new String(params.KUBE_CONFIG.decodeBase64())
                    // } else {
                    //     error "KUBE_CONFIG is not provided"
                    // }
                  
                    // Decode and save SECRETS_YAML
                    if (params.SECRETS_YAML) {
                        writeFile file: '/tmp/jenkins-k8s-apply/secrets.yaml', text: new String(params.SECRETS_YAML.decodeBase64())
                    } else {
                        error "SECRETS_YAML is not provided"
                    }
                    
                    // Debug: Check if files were created
                    sh 'ls -l /tmp/jenkins-k8s-apply'
                    sh 'echo "secrets.yaml file contents:" && cat /tmp/jenkins-k8s-apply/secrets.yaml'
                }
            }
        }

        stage('Apply K8s Config') {
            steps {
                script {
                    withCredentials([file(credentialsId: params.KUBECONFIG_CREDENTIAL_ID, variable: 'KUBECONFIG')]) {
                        if (fileExists('/tmp/jenkins-k8s-apply/secrets.yaml')) {
                            sh """
                                docker run --rm \
                                -v ${KUBECONFIG}:/tmp/kubeconfig \
                                -v /tmp/jenkins-k8s-apply/secrets.yaml:/tmp/secrets.yaml \
                                --name dind-service \
                                ${DOCKER_IMAGE} \
                                kubectl --kubeconfig /tmp/kubeconfig -n ${params.NAMESPACE} apply -f /tmp/secrets.yaml
                            """
                        } else {
                            error "Required secrets.yaml file is missing. Check if it was uploaded correctly."
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up temporary files
            sh 'rm -rf /tmp/jenkins-k8s-apply'
        }
        success {
            echo "Secret successfully applied to namespace ${params.NAMESPACE}"
        }
        failure {
            echo "Pipeline failed. Check the logs for details."
        }
    }
}
