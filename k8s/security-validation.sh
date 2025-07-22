#!/bin/bash

# Kubernetes Security Validation Script
# This script validates security configurations in the Kubernetes deployment

set -e

# Configuration
NAMESPACE="typescript-namespace"
APP_LABEL="app=typescript-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Kubernetes Security Validation for ${NAMESPACE}${NC}"

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if kubectl is available and cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Unable to connect to Kubernetes cluster${NC}"
    exit 1
fi

print_status 0 "Connected to Kubernetes cluster"

# Check if namespace exists
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    print_status 1 "Namespace ${NAMESPACE} does not exist"
    exit 1
fi

print_status 0 "Namespace ${NAMESPACE} exists"

echo -e "\n${BLUE}🛡️  Security Configuration Validation${NC}"

# 1. Check Pod Security Context
print_info "Checking Pod Security Context..."
PODS=$(kubectl get pods -n ${NAMESPACE} -l ${APP_LABEL} -o name 2>/dev/null || echo "")

if [ -z "$PODS" ]; then
    print_status 1 "No pods found with label ${APP_LABEL}"
    exit 1
fi

for pod in $PODS; do
    pod_name=$(basename $pod)
    
    # Check if running as non-root
    RUN_AS_USER=$(kubectl get $pod -n ${NAMESPACE} -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null || echo "")
    if [ "$RUN_AS_USER" = "1001" ]; then
        print_status 0 "Pod $pod_name runs as non-root user (UID: $RUN_AS_USER)"
    else
        print_status 1 "Pod $pod_name security context issue - runAsUser: $RUN_AS_USER"
    fi
    
    # Check read-only root filesystem
    READONLY_FS=$(kubectl get $pod -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null || echo "false")
    if [ "$READONLY_FS" = "true" ]; then
        print_status 0 "Pod $pod_name has read-only root filesystem"
    else
        print_warning "Pod $pod_name does not have read-only root filesystem"
    fi
    
    # Check allowPrivilegeEscalation
    PRIV_ESC=$(kubectl get $pod -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].securityContext.allowPrivilegeEscalation}' 2>/dev/null || echo "true")
    if [ "$PRIV_ESC" = "false" ]; then
        print_status 0 "Pod $pod_name prevents privilege escalation"
    else
        print_status 1 "Pod $pod_name allows privilege escalation"
    fi
done

# 2. Check Service Account Configuration
print_info "Checking Service Account Configuration..."
SA_NAME=$(kubectl get deployment typescript-app-deployment -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null || echo "default")
if [ "$SA_NAME" != "default" ]; then
    print_status 0 "Using custom service account: $SA_NAME"
    
    # Check automountServiceAccountToken
    AUTO_MOUNT=$(kubectl get deployment typescript-app-deployment -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.automountServiceAccountToken}' 2>/dev/null || echo "true")
    if [ "$AUTO_MOUNT" = "false" ]; then
        print_status 0 "Service account token auto-mounting is disabled"
    else
        print_warning "Service account token auto-mounting is enabled"
    fi
else
    print_warning "Using default service account"
fi

# 3. Check Network Policies
print_info "Checking Network Policies..."
NP_COUNT=$(kubectl get networkpolicy -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$NP_COUNT" -gt 0 ]; then
    print_status 0 "Network policies are configured ($NP_COUNT policies)"
    kubectl get networkpolicy -n ${NAMESPACE} --no-headers | while read np; do
        np_name=$(echo $np | awk '{print $1}')
        print_info "  - Network Policy: $np_name"
    done
else
    print_status 1 "No network policies found"
fi

# 4. Check Resource Limits
print_info "Checking Resource Limits..."
DEPLOYMENT_NAME="typescript-app-deployment"
CPU_LIMIT=$(kubectl get deployment $DEPLOYMENT_NAME -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || echo "")
MEM_LIMIT=$(kubectl get deployment $DEPLOYMENT_NAME -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "")

if [ -n "$CPU_LIMIT" ] && [ -n "$MEM_LIMIT" ]; then
    print_status 0 "Resource limits configured - CPU: $CPU_LIMIT, Memory: $MEM_LIMIT"
else
    print_status 1 "Resource limits not properly configured"
fi

# 5. Check Health Checks
print_info "Checking Health Checks..."
LIVENESS=$(kubectl get deployment $DEPLOYMENT_NAME -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' 2>/dev/null || echo "")
READINESS=$(kubectl get deployment $DEPLOYMENT_NAME -n ${NAMESPACE} -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' 2>/dev/null || echo "")

if [ -n "$LIVENESS" ]; then
    print_status 0 "Liveness probe configured"
else
    print_status 1 "Liveness probe not configured"
fi

if [ -n "$READINESS" ]; then
    print_status 0 "Readiness probe configured"
else
    print_status 1 "Readiness probe not configured"
fi

# 6. Check HPA Configuration
print_info "Checking Horizontal Pod Autoscaler..."
HPA_EXISTS=$(kubectl get hpa -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$HPA_EXISTS" -gt 0 ]; then
    print_status 0 "HPA is configured"
    kubectl get hpa -n ${NAMESPACE} --no-headers | while read hpa; do
        hpa_name=$(echo $hpa | awk '{print $1}')
        min_pods=$(echo $hpa | awk '{print $5}')
        max_pods=$(echo $hpa | awk '{print $6}')
        print_info "  - HPA: $hpa_name (Min: $min_pods, Max: $max_pods)"
    done
else
    print_warning "HPA not configured"
fi

# 7. Check Pod Disruption Budget
print_info "Checking Pod Disruption Budget..."
PDB_EXISTS=$(kubectl get pdb -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l || echo "0")
if [ "$PDB_EXISTS" -gt 0 ]; then
    print_status 0 "PDB is configured"
else
    print_warning "PDB not configured"
fi

# 8. Check Image Tags
print_info "Checking Image Security..."
for pod in $PODS; do
    pod_name=$(basename $pod)
    IMAGE=$(kubectl get $pod -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || echo "")
    
    if [[ "$IMAGE" == *":latest" ]]; then
        print_warning "Pod $pod_name uses 'latest' tag: $IMAGE"
    elif [[ "$IMAGE" == *":"* ]]; then
        print_status 0 "Pod $pod_name uses specific tag: $IMAGE"
    else
        print_warning "Pod $pod_name uses no tag (defaults to latest): $IMAGE"
    fi
done

# 9. Check Secret and ConfigMap Security
print_info "Checking ConfigMap and Secret Configuration..."
CM_COUNT=$(kubectl get configmap -n ${NAMESPACE} --no-headers 2>/dev/null | wc -l || echo "0")
SECRET_COUNT=$(kubectl get secret -n ${NAMESPACE} --no-headers | grep -v "kubernetes.io/service-account-token" | wc -l || echo "0")

if [ "$CM_COUNT" -gt 0 ]; then
    print_status 0 "ConfigMaps are configured ($CM_COUNT found)"
else
    print_warning "No ConfigMaps found"
fi

if [ "$SECRET_COUNT" -gt 0 ]; then
    print_status 0 "Secrets are configured ($SECRET_COUNT found)"
else
    print_warning "No custom secrets found"
fi

# 10. Check Pod Security Standards (K8s 1.23+)
print_info "Checking Pod Security Standards..."
PSS_LEVEL=$(kubectl get namespace ${NAMESPACE} -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || echo "")
if [ -n "$PSS_LEVEL" ]; then
    print_status 0 "Pod Security Standard enforced at level: $PSS_LEVEL"
else
    print_warning "No Pod Security Standard configured"
fi

echo -e "\n${BLUE}🔍 Runtime Security Validation${NC}"

# 11. Check running processes in pods
print_info "Checking running processes..."
for pod in $PODS; do
    pod_name=$(basename $pod)
    
    # Check if pod is ready
    if kubectl wait --for=condition=ready $pod -n ${NAMESPACE} --timeout=10s &>/dev/null; then
        # Get user ID of running process
        USER_ID=$(kubectl exec $pod -n ${NAMESPACE} -- id -u 2>/dev/null || echo "unknown")
        if [ "$USER_ID" = "1001" ]; then
            print_status 0 "Pod $pod_name process runs as UID $USER_ID (non-root)"
        else
            print_status 1 "Pod $pod_name process runs as UID $USER_ID"
        fi
        
        # Check if we can write to root filesystem
        if kubectl exec $pod -n ${NAMESPACE} -- touch /test-write 2>/dev/null; then
            print_status 1 "Pod $pod_name has writable root filesystem"
            kubectl exec $pod -n ${NAMESPACE} -- rm -f /test-write 2>/dev/null || true
        else
            print_status 0 "Pod $pod_name has read-only root filesystem"
        fi
    else
        print_warning "Pod $pod_name is not ready, skipping runtime checks"
    fi
done

# 12. Verify service exposure
print_info "Checking service exposure..."
SERVICE_TYPE=$(kubectl get service typescript-app-service -n ${NAMESPACE} -o jsonpath='{.spec.type}' 2>/dev/null || echo "")
if [ "$SERVICE_TYPE" = "ClusterIP" ]; then
    print_status 0 "Service uses ClusterIP (internal only)"
elif [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
    print_warning "Service uses LoadBalancer (external exposure)"
elif [ "$SERVICE_TYPE" = "NodePort" ]; then
    print_warning "Service uses NodePort (potential external exposure)"
else
    print_info "Service type: $SERVICE_TYPE"
fi

# Summary
echo -e "\n${BLUE}📊 Security Validation Summary${NC}"
print_info "Validation completed for namespace: $NAMESPACE"
print_info "Check the results above for any security issues that need attention"

# Optional: Check for known security tools
echo -e "\n${BLUE}🔧 Security Tools Check${NC}"
if kubectl get pods -A | grep -q "falco\|twistlock\|aqua\|sysdig" &>/dev/null; then
    print_status 0 "Security monitoring tools detected"
else
    print_info "No security monitoring tools detected (optional)"
fi

# Check for network policy controller
if kubectl get pods -n kube-system | grep -q "calico\|cilium\|weave" &>/dev/null; then
    print_status 0 "Network policy controller detected"
else
    print_warning "Network policy controller not detected"
fi

echo -e "\n${GREEN}🎉 Security validation completed!${NC}"
