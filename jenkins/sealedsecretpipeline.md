# Sealed Secrets Jenkins Pipeline Ref.

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Setup Instructions](#setup-instructions)
5. [Pipeline Details](#pipeline-details)


## Overview
This project implements a Jenkins pipeline for encrypting Kubernetes secrets using Bitnami's Sealed Secrets. The pipeline allows users to upload regular Kubernetes secrets and converts them into sealed secrets, which can be safely stored in version control systems.

### Key Features
- Secure encryption of Kubernetes secrets
- Support for base64-encoded secret files
- Automated certificate management
- Artifact generation and storage
- Docker-in-Docker (DinD) support for isolated execution

## Architecture

### Components
1. **Jenkins Server**


2. **Custom Docker Image**
   - Based on Docker-in-Docker (DinD)
   - Includes kubectl and kubeseal tools


3. **K8s Cluster ( i used AKS)**
   - [Runs the Sealed Secrets controller](https://github.com/bitnami-labs/sealed-secrets)
   - Manages secret decryption 

### Workflow
1. User uploads Regaular k8s config secret YAML file to Jenkins
2. Pipeline fetches public cert from Sealed Secrets controller
3. Secret is encrypted using kubeseal
4. Sealed secret is saved as artifact

## Prerequisites

### Jenkins Server Requirements
- Ubuntu OS
- Jenkins installation
- Required plugins:
  - File Parameter plugin
  - Config File Provider plugin
  - Default Jenkins plugins
  - (Optional) Publish Over plugin for artifact display

### Docker Image
The custom Docker image (`docker-dind-kube-ctl-seal`) is built using the following Dockerfile:

```dockerfile
FROM docker:dind

# Install kubectl
RUN apk add --no-cache curl wget && \
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Install kubeseal
RUN wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.27.1/kubeseal-0.27.1-linux-amd64.tar.gz && \
    tar zxf kubeseal-0.27.1-linux-amd64.tar.gz && \
    chmod +x ./kubeseal && \
    mv ./kubeseal /usr/local/bin/kubeseal

# Expose Docker daemon ports
EXPOSE 2375 2376

# Start Docker daemon
CMD ["dockerd-entrypoint.sh"]
```

## Setup Instructions

### 1. Sealed Secret Controler Setup

- Ensure you completed the prequestries, i.e. K8s cluser, Secret file, jenkins,  docker-dind image. 


### 2. Sealed Secret Controler Setup

Install the Sealed Secret controller.

```bash 
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
hem repo update
helm install sealed-secrets --namespace kube-system --version {2.16} sealed-secrets/sealed-secrets
```

### 3. Docker Image Build
```bash
# Clone repository and build image
git clone <repository-url>
cd <repository-directory>
docker build -t Dockerfile-dind-kube-ctl-seal .
```
### 4. Pipeline Setup
1. Create new Jenkins Pipeline job
2. Copy contents of `sealedsecret-pipeline.js` into the pipeline definition
3. Configure credentials for Kubernetes cluster access

## Pipeline Details

### Parameters
- `NAMESPACE`: Target Kubernetes namespace
- `KUBECONFIG_CREDENTIAL_ID`: Jenkins credential ID for kubeconfig
- `SECRETS_YAML`: Base64-encoded secret file
- `STORE_CERT`: Option to store public certificate

### Stages
1. **Prepare Workspace**
2. **Apply K8s Config & Fetch Certificate**
3. **Archive Artifacts**

### Applying Sealed Secret
```bash
# Apply sealed secret to cluster
kubectl apply -f sealed-secrets.yaml
```
