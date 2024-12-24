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
    }

    stages {
        stage('Environment Setup') {
            steps {
                script {
                    echo "Selected Environment: ${params.ENVIRONMENT}"
                    
                    // Define cluster list based on environment
                    def clusters = []
                    if (params.ENVIRONMENT == 'Production') {
                        clusters = [
                            [id: 'prod-cluster-1', name: 'Production Cluster 1', credentialId: 'Production_1'],
                            [id: 'prod-cluster-2', name: 'Production Cluster 2', credentialId: 'Production_2']
                        ]
                    } else {
                        clusters = [
                            [id: 'non-prod-cluster', name: 'Non-Production Cluster', credentialId: 'Stage']
                        ]
                    }
                    
                    // Store clusters info in environment variables
                    env.CLUSTER_IDS = clusters.collect { it.id }.join(',')
                    clusters.each { cluster ->
                        env["CLUSTER_${cluster.id}_NAME"] = cluster.name
                        env["CLUSTER_${cluster.id}_CRED"] = cluster.credentialId
                    }
                    
                    echo "Number of target clusters: ${clusters.size()}"
                    clusters.each { cluster ->
                        echo "Cluster: ${cluster.name} (${cluster.id})"
                    }
                }
            }
        }

        stage('Prepare Workspace') {
            steps {
                script {
                    echo "=== Stage: Prepare Workspace ==="
                    
                    sh """
                        set -x
                        mkdir -p ${WORK_DIR}
                        mkdir -p ${WORKSPACE}/${ARTIFACTS_DIR}
                        rm -f ${WORK_DIR}/* || true
                        rm -rf ${WORKSPACE}/${ARTIFACTS_DIR}/* || true
                        
                        # Environment-specific cleanup
                        if [ "${params.ENVIRONMENT}" = "Non-Production" ]; then
                            rm -rf ${WORKSPACE}/${ARTIFACTS_DIR}/prod-*
                        else
                            rm -rf ${WORKSPACE}/${ARTIFACTS_DIR}/non-prod-*
                        fi
                    """


                    if (params.SECRETS_YAML) {
                        writeFile file: "${WORK_DIR}/secrets.yaml.b64", text: params.SECRETS_YAML
                        sh """
                            set -x
                            base64 --decode < ${WORK_DIR}/secrets.yaml.b64 > ${WORK_DIR}/secrets.yaml
                            echo "First few lines of decoded file (sanitized):"
                            head -n 5 ${WORK_DIR}/secrets.yaml | grep -v 'data:' || echo "File appears to be empty"
                        """
                    } else {
                        error "SECRETS_YAML parameter is not provided"
                    }
                }
            }
        }

        stage('Process Clusters') {
            steps {
                script {
                    def clusterIds = env.CLUSTER_IDS.split(',')
                    def parallelStages = [:]
                    
                    clusterIds.each { clusterId ->
                        def clusterName = env["CLUSTER_${clusterId}_NAME"]
                        def credentialId = env["CLUSTER_${clusterId}_CRED"]
                        
                        parallelStages[clusterName] = {
                            stage("Process ${clusterName}") {
                                withCredentials([file(credentialsId: credentialId, variable: 'KUBECONFIG')]) {
                                    def clusterWorkDir = "${WORK_DIR}/${clusterId}"
                                    def clusterArtifactsDir = "${WORKSPACE}/${ARTIFACTS_DIR}/${clusterId}"
                                    
                                    sh """
                                        mkdir -p ${clusterWorkDir}
                                        mkdir -p ${clusterArtifactsDir}
                                        cp ${WORK_DIR}/secrets.yaml ${clusterWorkDir}/
                                    """

                                    sh """
                                        set -x
                                        docker run --rm \
                                        -v \${KUBECONFIG}:/tmp/kubeconfig \
                                        -v ${clusterWorkDir}/secrets.yaml:/tmp/secrets.yaml \
                                        -e KUBECONFIG=/tmp/kubeconfig \
                                        --name dind-service-${clusterId} \
                                        ${DOCKER_IMAGE} kubeseal \
                                            --controller-name=${CONTROLLER_NAME} \
                                            --controller-namespace=${CONTROLLER_NAMESPACE} \
                                            --kubeconfig=/tmp/kubeconfig \
                                            --fetch-cert > ${clusterWorkDir}/${CERT_FILE}
                                    """

                                    sh """
                                        set -x
                                        docker run --rm \
                                        -v \${KUBECONFIG}:/tmp/kubeconfig \
                                        -v ${clusterWorkDir}/secrets.yaml:/tmp/secrets.yaml \
                                        -v ${clusterWorkDir}/${CERT_FILE}:/tmp/${CERT_FILE} \
                                        -e KUBECONFIG=/tmp/kubeconfig \
                                        --name dind-service-${clusterId} \
                                        ${DOCKER_IMAGE} sh -c "kubeseal \
                                            --controller-name=${CONTROLLER_NAME} \
                                            --controller-namespace=${CONTROLLER_NAMESPACE} \
                                            --format yaml \
                                            --cert /tmp/${CERT_FILE} \
                                            --namespace=${params.NAMESPACE} \
                                            < /tmp/secrets.yaml" > ${clusterArtifactsDir}/sealed-secrets.yaml
                                    """

                                    sh """
                                        echo "Generated on: \$(date)" > ${clusterArtifactsDir}/README.txt
                                        echo "Cluster: ${clusterName}" >> ${clusterArtifactsDir}/README.txt
                                        echo "Environment: ${params.ENVIRONMENT}" >> ${clusterArtifactsDir}/README.txt
                                        echo "Namespace: ${params.NAMESPACE}" >> ${clusterArtifactsDir}/README.txt
                                        echo "Controller: ${CONTROLLER_NAME}" >> ${clusterArtifactsDir}/README.txt
                                        echo "Controller Namespace: ${CONTROLLER_NAMESPACE}" >> ${clusterArtifactsDir}/README.txt
                                    """
                                }
                            }
                        }
                    }
                    
                    parallel parallelStages
                }
            }
        }
    }

    post {
        always {
            script {
                echo "=== Post-Build Actions ==="
                echo "Cleaning up temporary files..."
                sh "rm -rf ${WORK_DIR}"
                if (params.ENVIRONMENT == 'Production') {
                    archiveArtifacts artifacts: "${ARTIFACTS_DIR}/prod-*/**/README.txt,${ARTIFACTS_DIR}/prod-*/**/sealed-secrets.yaml", fingerprint: true
                } else {
                    archiveArtifacts artifacts: "${ARTIFACTS_DIR}/non-prod-*/**/README.txt,${ARTIFACTS_DIR}/non-prod-*/**/sealed-secrets.yaml", fingerprint: true

                }                

            }
        }
        success {
            script {
                echo "=== Build Successful ==="
                def successMsg = """Pipeline completed successfully!
                
                Environment: ${params.ENVIRONMENT}
                
                Available artifacts in Jenkins UI (Build Artifacts section):
                - ${ARTIFACTS_DIR}/*/sealed-secrets.yaml - Encrypted sealed secrets
                - ${ARTIFACTS_DIR}/*/README.txt - Generation details and instructions
                
                To download:
                1. Click on this build number
                2. Select 'Build Artifacts' in the left sidebar
                3. Find files in the ${ARTIFACTS_DIR}/ directory
                """
                echo successMsg
            }
        }
        failure {
            script {
                def failureMsg = """=== Build Failed ===
                Pipeline failed. Please check:
                1. The logs above for detailed error messages
                2. Whether the secret YAML was properly encoded
                3. If kubeconfig credentials are correct for all clusters in ${params.ENVIRONMENT} environment
                4. If the sealed-secrets controller is running in each cluster
                
                Environment: ${params.ENVIRONMENT}
                """
                echo failureMsg
            }
        }
    }
}