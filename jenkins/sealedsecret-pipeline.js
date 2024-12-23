pipeline {
    agent any

    parameters {
        string(name: 'NAMESPACE', defaultValue: 'default', description: 'Kubernetes namespace for the sealed secret')
        choice(
            name: 'ENVIRONMENT',
            choices: ['Non-Production', 'Production'],
            description: 'Select the target environment'
        )
        base64File(name: 'SECRETS_YAML', description: 'Upload Secrets.yaml file to apply to the cluster')
        booleanParam(name: 'STORE_CERT', defaultValue: true, description: 'Store the public certificate for future use')
    }

    environment {
        WORK_DIR = '/tmp/jenkins-k8s-apply'
        CONTROLLER_NAMESPACE = 'kube-system'
        CONTROLLER_NAME = 'sealed-secrets'
        CERT_FILE = 'sealed-secrets-cert.pem'
        DOCKER_IMAGE = 'docker-dind-kube-secret'
        ARTIFACTS_DIR = 'sealed-secrets-artifacts'
        // Predefined credential IDs for different environments
        PROD_KUBECONFIG_ID = 'Production'
        NONPROD_KUBECONFIG_ID = 'Stage' // Default to Stage for Non-Production
    }

    stages {
        stage('Environment Validation') {
            steps {
                script {
                    echo "=== Environment Validation ==="
                    
                    // Set the appropriate kubeconfig credential ID based on environment
                    env.SELECTED_KUBECONFIG_ID = params.ENVIRONMENT == 'Production' 
                        ? env.PROD_KUBECONFIG_ID 
                        : env.NONPROD_KUBECONFIG_ID

                    echo "Selected Environment: ${params.ENVIRONMENT}"
                    echo "Using kubeconfig credential: ${env.SELECTED_KUBECONFIG_ID}"

                    // Additional validation for Production environment
                    if (params.ENVIRONMENT == 'Production') {
                        // Add any production-specific validations here
                        echo "Production environment selected - applying additional safeguards"
                        // Example: You could add approval steps or additional validations
                    }
                }
            }
        }

        stage('Prepare Workspace') {
            steps {
                script {
                    echo "=== Prepare Workspace ==="
                    echo "Creating directories and cleaning up old files..."
                    
                    sh """
                        set -x
                        mkdir -p ${WORK_DIR}
                        mkdir -p ${WORKSPACE}/${ARTIFACTS_DIR}
                        
                        echo "Current workspace & Work Dir contents:"
                        ls -laRt ${WORKSPACE} || echo "Directory is empty"
                        ls -laRt ${WORK_DIR} || echo "Directory is empty"
                        
                        rm -f ${WORK_DIR}/* || true
                        rm -f ${WORKSPACE}/${ARTIFACTS_DIR}/* || true
                        
                        echo "Work directory contents after cleanup:"
                        ls -la ${WORK_DIR} || echo "Directory is empty"
                        ls -la ${WORKSPACE}/${ARTIFACTS_DIR} || echo "Directory is empty"
                    """

                    echo "Processing base64 encoded secret..."
                    if (params.SECRETS_YAML) {
                        echo "Secret data provided, writing to file..."
                        writeFile file: "${WORK_DIR}/secrets.yaml.b64", text: params.SECRETS_YAML
                        
                        sh """
                            set -x
                            ls -l ${WORK_DIR}/secrets.yaml.b64
                            
                            echo "Decoding base64 content..."
                            base64 --decode < ${WORK_DIR}/secrets.yaml.b64 > ${WORK_DIR}/secrets.yaml
                            
                            echo "Checking decoded file..."
                            ls -l ${WORK_DIR}/secrets.yaml
                            
                            echo "First few lines of decoded file (sanitized):"
                            head -n 5 ${WORK_DIR}/secrets.yaml | grep -v 'data:' || echo "File appears to be empty"
                        """
                    } else {
                        error "SECRETS_YAML parameter is not provided"
                    }
                }
            }
        }

        stage('Apply K8s Config & Fetch Public Certificate') {
            steps {
                script {
                    echo "=== Apply K8s Config & Fetch Public Certificate ==="
                    
                    withCredentials([file(credentialsId: env.SELECTED_KUBECONFIG_ID, variable: 'KUBECONFIG')]) {
                        echo "Checking for required files..."
                        sh """
                            set -x
                            echo "Work directory contents:"
                            ls -la ${WORK_DIR}
                            
                            echo "Checking kubeconfig file:"
                            ls -l \${KUBECONFIG}
                        """
                        
                        if (fileExists("${WORK_DIR}/secrets.yaml")) {
                            echo "Secret file exists, proceeding with certificate fetch..."
                            
                            sh """
                                set -x
                                echo "Listing the pods..."
                                docker run --rm \
                                -v \${KUBECONFIG}:/tmp/kubeconfig \
                                -v ${WORK_DIR}/secrets.yaml:/tmp/secrets.yaml \
                                --name dind-service \
                                ${DOCKER_IMAGE} kubectl get pods -A --kubeconfig=/tmp/kubeconfig
                                
                            """
                            
                            sh """
                                set -x
                                echo "Fetching sealed secrets certificate..."
                                docker run --rm \
                                -v \${KUBECONFIG}:/tmp/kubeconfig \
                                -v ${WORK_DIR}/secrets.yaml:/tmp/secrets.yaml \
                                --name dind-service \
                                ${DOCKER_IMAGE} kubeseal \
                                    --controller-name=${CONTROLLER_NAME} \
                                    --controller-namespace=${CONTROLLER_NAMESPACE} \
                                    --kubeconfig=/tmp/kubeconfig \
                                    --fetch-cert > ${WORK_DIR}/${CERT_FILE}
                                
                                echo "Checking certificate file:"
                                ls -l ${WORK_DIR}/${CERT_FILE}
                            """

                            if (params.STORE_CERT) {
                                sh """
                                    set -x
                                    cp ${WORK_DIR}/${CERT_FILE} ${WORKSPACE}/${ARTIFACTS_DIR}/
                                    echo "Certificate stored in artifacts directory:"
                                    ls -l ${WORKSPACE}/${ARTIFACTS_DIR}/${CERT_FILE}
                                """
                            }

                            echo "Creating sealed secret..."
                            sh """
                                set -x
                                docker run --rm \
                                -v \${KUBECONFIG}:/tmp/kubeconfig \
                                -v ${WORK_DIR}/secrets.yaml:/tmp/secrets.yaml \
                                -v ${WORK_DIR}/${CERT_FILE}:${WORK_DIR}/${CERT_FILE} \
                                --name dind-service \
                                ${DOCKER_IMAGE} sh -c "kubeseal \
                                    --controller-name=${CONTROLLER_NAME} \
                                    --controller-namespace=${CONTROLLER_NAMESPACE} \
                                    --format yaml \
                                    --cert ${WORK_DIR}/${CERT_FILE} \
                                    --namespace=${params.NAMESPACE} \
                                    < /tmp/secrets.yaml" > ${WORKSPACE}/${ARTIFACTS_DIR}/sealed-secrets.yaml
                                
                                echo "Checking sealed secret file:"
                                ls -l ${WORKSPACE}/${ARTIFACTS_DIR}/sealed-secrets.yaml
                            """

                            echo "Creating documentation..."
                            sh """
                                set -x
                                echo "Generated on: \$(date)" > ${WORKSPACE}/${ARTIFACTS_DIR}/README.txt
                                echo "Environment: ${params.ENVIRONMENT}" >> ${WORKSPACE}/${ARTIFACTS_DIR}/README.txt
                                echo "Namespace: ${params.NAMESPACE}" >> ${WORKSPACE}/${ARTIFACTS_DIR}/README.txt
                                echo "Controller: ${CONTROLLER_NAME}" >> ${WORKSPACE}/${ARTIFACTS_DIR}/README.txt
                                echo "Controller Namespace: ${CONTROLLER_NAMESPACE}" >> ${WORKSPACE}/${ARTIFACTS_DIR}/README.txt
                            """

                            archiveArtifacts artifacts: "${ARTIFACTS_DIR}/**/*", fingerprint: true
                        } else {
                            error "Required secrets.yaml file is missing at ${WORK_DIR}/secrets.yaml. Check previous stage logs."
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "=== Post-Build Actions ==="
                echo "Cleaning up temporary files..."
                sh """
                    set -x
                    echo "Work directory contents before cleanup:"
                    ls -la ${WORK_DIR} || echo "Directory not found"
                    
                    rm -rf ${WORK_DIR}
                    
                    echo "Artifacts directory contents:"
                    ls -lR ${WORKSPACE}/${ARTIFACTS_DIR} || echo "No artifacts found"
                """
            }
        }
        success {
            script {
                echo "=== Build Successful ==="
                def artifactMsg = """
                Pipeline completed successfully!
                
                Environment: ${params.ENVIRONMENT}
                Available artifacts in Jenkins UI (Build Artifacts section):
                1. sealed-secrets.yaml - Encrypted sealed secret
                2. ${CERT_FILE} - Public certificate (if enabled)
                3. README.txt - Generation details and instructions
                
                To download:
                1. Click on this build number
                2. Select 'Build Artifacts' in the left sidebar
                3. Find files in the ${ARTIFACTS_DIR}/ directory
                """
                echo artifactMsg
            }
        }
        failure {
            script {
                echo """
                === Build Failed ===
                Pipeline failed. Please check:
                1. The logs above for detailed error messages
                2. Whether the secret YAML was properly encoded
                3. If kubeconfig credentials are correct for ${params.ENVIRONMENT} environment
                4. If the sealed-secrets controller is running in the cluster
                
                Last known state of working directory:
                """
                sh """
                    ls -la ${WORK_DIR} || echo "Work directory not accessible"
                    ls -la ${WORKSPACE}/${ARTIFACTS_DIR} || echo "No artifacts generated"
                """
            }
        }
    }
}