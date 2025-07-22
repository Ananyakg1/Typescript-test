# Deployment script for manual deployment
#!/bin/bash

set -e

# Configuration
NAMESPACE="typescript-namespace"
APP_NAME="typescript-app"
IMAGE_TAG=${1:-"latest"}
REGISTRY_NAME=${REGISTRY_NAME:-"your-registry.azurecr.io"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting deployment of ${APP_NAME} to Kubernetes${NC}"

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Unable to connect to Kubernetes cluster${NC}"
    exit 1
fi

print_status 0 "Connected to Kubernetes cluster"

# Create namespace if it doesn't exist
print_info "Checking namespace: ${NAMESPACE}"
if kubectl get namespace ${NAMESPACE} &> /dev/null; then
    print_info "Namespace ${NAMESPACE} already exists"
else
    print_info "Creating namespace: ${NAMESPACE}"
    kubectl apply -f k8s/namespace.yaml
    print_status $? "Namespace created"
fi

# Apply ConfigMap and Secrets
print_info "Applying ConfigMap and Secrets"
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
print_status $? "ConfigMap and Secrets applied"

# Update image tag in deployment if provided
if [ "$IMAGE_TAG" != "latest" ]; then
    print_info "Updating deployment with image tag: ${IMAGE_TAG}"
    sed -i.bak "s|image: typescript:latest|image: ${REGISTRY_NAME}/typescript:${IMAGE_TAG}|g" k8s/deployment.yaml
    print_status $? "Image tag updated"
fi

# Apply Deployment and Services
print_info "Applying Deployment and Services"
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
print_status $? "Deployment and Services applied"

# Apply Network Policies
print_info "Applying Network Policies"
kubectl apply -f k8s/network-policy.yaml
print_status $? "Network Policies applied"

# Apply HPA and PDB
print_info "Applying HPA and PDB"
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
print_status $? "HPA and PDB applied"

# Apply monitoring (if Prometheus is available)
print_info "Applying monitoring configuration"
if kubectl get crd servicemonitors.monitoring.coreos.com &> /dev/null; then
    kubectl apply -f k8s/monitoring.yaml
    print_status $? "Monitoring configuration applied"
else
    print_warning "ServiceMonitor CRD not found, skipping monitoring configuration"
fi

# Wait for deployment to be ready
print_info "Waiting for deployment to be ready..."
kubectl rollout status deployment/${APP_NAME}-deployment -n ${NAMESPACE} --timeout=600s
print_status $? "Deployment is ready"

# Show deployment status
print_info "Deployment Status:"
kubectl get all -n ${NAMESPACE} -l app=${APP_NAME}

# Show HPA status
print_info "HPA Status:"
kubectl get hpa -n ${NAMESPACE}

# Test health endpoint (if available)
print_info "Testing application health..."
SERVICE_IP=$(kubectl get svc ${APP_NAME}-service -n ${NAMESPACE} -o jsonpath='{.spec.clusterIP}')
print_info "Service ClusterIP: ${SERVICE_IP}"

# Create a test pod to check connectivity
kubectl run health-check-${RANDOM} --rm -i --restart=Never --image=curlimages/curl:latest -- \
    curl -f "http://${APP_NAME}-service.${NAMESPACE}.svc.cluster.local/health" && \
    print_status 0 "Health check passed" || \
    print_warning "Health check failed or endpoint not available"

# Restore original deployment file if we modified it
if [ -f k8s/deployment.yaml.bak ]; then
    mv k8s/deployment.yaml.bak k8s/deployment.yaml
fi

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo "- Application: ${APP_NAME}"
echo "- Namespace: ${NAMESPACE}"
echo "- Image: ${REGISTRY_NAME}/typescript:${IMAGE_TAG}"
echo "- Service: ${APP_NAME}-service.${NAMESPACE}.svc.cluster.local"
