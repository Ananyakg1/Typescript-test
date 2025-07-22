# Kubernetes Deployment with Security Best Practices

This directory contains comprehensive Kubernetes deployment configurations for the TypeScript application with enterprise-grade security best practices and CI/CD integration.

## 🛡️ Security Features

### 1. **Security Contexts**
- **Non-root execution**: All containers run as UID 1001
- **Read-only root filesystem**: Prevents runtime modifications
- **Dropped capabilities**: All Linux capabilities dropped except NET_BIND_SERVICE
- **Security profiles**: RuntimeDefault seccomp profile enabled
- **No privilege escalation**: `allowPrivilegeEscalation: false`

### 2. **Network Security**
- **Network policies**: Strict ingress/egress rules
- **ClusterIP services**: No external exposure by default
- **Namespace isolation**: Dedicated namespace with network boundaries
- **Pod-to-pod communication**: Controlled via network policies

### 3. **Resource Security**
- **Resource limits**: CPU and memory constraints
- **Ephemeral storage limits**: Prevent disk exhaustion
- **Pod Disruption Budget**: Maintain availability during updates
- **Horizontal Pod Autoscaler**: Dynamic scaling based on metrics

### 4. **Configuration Security**
- **ConfigMaps**: Non-sensitive configuration
- **Secrets**: Sensitive data with proper access controls
- **Service Account**: Dedicated SA with minimal permissions
- **No service account token mounting**: `automountServiceAccountToken: false`

## 📁 File Structure

```
k8s/
├── namespace.yaml              # Namespace and network policy
├── configmap.yaml              # Application configuration
├── secret.yaml                 # Sensitive configuration
├── deployment.yaml             # Main application deployment
├── service.yaml                # ClusterIP services
├── network-policy.yaml         # Network access rules
├── hpa.yaml                    # Horizontal Pod Autoscaler
├── pdb.yaml                    # Pod Disruption Budget
├── pod-security-policy.yaml    # Pod Security Policy (K8s < 1.25)
├── monitoring.yaml             # Prometheus monitoring
├── kustomization.yaml          # Kustomize configuration
└── deploy.sh                   # Manual deployment script
```

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster (1.25+)
- kubectl configured
- Azure Container Registry access
- Prometheus Operator (optional, for monitoring)

### Deploy via GitHub Actions (Recommended)

The application automatically deploys via GitHub Actions when pushing to `main` or `develop` branches.

**Required GitHub Secrets:**
```bash
AZURE_CLIENT_ID              # Azure Service Principal Client ID
AZURE_CLIENT_SECRET          # Azure Service Principal Secret
AZURE_SUSCRIPTION_ID         # Azure Subscription ID
AZURE_TENANT_ID              # Azure Tenant ID
REGISTRY_LOGIN_SERVER        # ACR login server
REGISTRY_USERNAME            # ACR username
REGISTRY_PASSWORD            # ACR password
AKS_CLUSTER_NAME            # AKS cluster name
AKS_RESOURCE_GROUP          # AKS resource group
```

### Manual Deployment

```bash
# Deploy with default settings
./k8s/deploy.sh

# Deploy with specific image tag
./k8s/deploy.sh "v1.2.3-abc123"

# Deploy using kubectl
kubectl apply -k k8s/
```

### Using Kustomize

```bash
# Deploy base configuration
kubectl apply -k k8s/

# Deploy with custom image
kustomize edit set image typescript=your-registry.azurecr.io/typescript:v1.2.3
kubectl apply -k k8s/
```

## 🔧 Configuration

### Application Settings (ConfigMap)

```yaml
NODE_ENV: "production"
PORT: "8080"
LOG_LEVEL: "info"
NODE_OPTIONS: "--max-old-space-size=1024"
ENABLE_SECURITY_HEADERS: "true"
```

### Resource Limits

```yaml
resources:
  limits:
    memory: "1Gi"
    cpu: "1000m"
    ephemeral-storage: "2Gi"
  requests:
    memory: "512Mi"
    cpu: "500m"
    ephemeral-storage: "1Gi"
```

### Auto-scaling Configuration

```yaml
minReplicas: 3
maxReplicas: 10
targetCPUUtilization: 70%
targetMemoryUtilization: 80%
```

## 🔍 Monitoring & Observability

### Health Checks
- **Liveness probe**: HTTP GET /health every 30s
- **Readiness probe**: HTTP GET /health every 10s
- **Startup probe**: HTTP GET /health (slow start protection)

### Metrics Collection
- **ServiceMonitor**: Prometheus metrics scraping
- **PrometheusRule**: Alerting rules for critical issues
- **Grafana dashboards**: Application performance metrics

### Logs
- **Structured logging**: JSON format for easy parsing
- **Log aggregation**: Compatible with Fluentd/Fluent Bit
- **Security audit**: Access and authentication logs

## 🚨 Security Scanning

The GitHub Actions workflow includes comprehensive security scanning:

### Trivy Scanner
- **Vulnerability scanning**: Critical and High severity
- **Secret detection**: Embedded secrets and credentials
- **SARIF output**: GitHub Security tab integration
- **Build failure**: Pipeline fails on critical vulnerabilities

### Scan Commands
```bash
# Manual vulnerability scan
trivy image --severity CRITICAL,HIGH your-image:tag

# Secret scan
trivy image --scanners secret your-image:tag

# Configuration scan
trivy k8s --report summary cluster
```

## 🔒 Security Best Practices

### ✅ Implemented Security Controls

- [x] Non-root container execution
- [x] Read-only root filesystem
- [x] Security contexts and profiles
- [x] Network policies and isolation
- [x] Resource limits and quotas
- [x] Health checks and monitoring
- [x] Secret management
- [x] Service account restrictions
- [x] Pod disruption budgets
- [x] Horizontal pod autoscaling
- [x] Vulnerability scanning
- [x] Security monitoring

### 🔧 Additional Recommendations

1. **Image Security**
   ```bash
   # Use specific image tags
   image: typescript:v1.2.3-abc123
   
   # Enable image policy webhook
   imagePolicyWebhook: true
   ```

2. **Secrets Management**
   ```bash
   # Use external secret management
   kubectl create secret generic app-secrets \
     --from-literal=db-password="$(az keyvault secret show ...)"
   ```

3. **Network Security**
   ```bash
   # Enable network policy enforcement
   kubectl label namespace typescript-namespace \
     network-policy=enabled
   ```

## 🐛 Troubleshooting

### Common Issues

**Pods not starting:**
```bash
# Check pod status
kubectl describe pod -n typescript-namespace -l app=typescript-app

# Check events
kubectl get events -n typescript-namespace --sort-by=.metadata.creationTimestamp
```

**Network connectivity issues:**
```bash
# Test service connectivity
kubectl run test-pod --rm -i --restart=Never --image=curlimages/curl:latest -- \
  curl -v typescript-app-service.typescript-namespace.svc.cluster.local

# Check network policies
kubectl describe networkpolicy -n typescript-namespace
```

**Resource issues:**
```bash
# Check resource usage
kubectl top pods -n typescript-namespace

# Check HPA status
kubectl describe hpa -n typescript-namespace
```

### Debugging Commands

```bash
# Get all resources in namespace
kubectl get all -n typescript-namespace

# Check pod logs
kubectl logs -f deployment/typescript-app-deployment -n typescript-namespace

# Get into pod for debugging (if allowed)
kubectl exec -it deployment/typescript-app-deployment -n typescript-namespace -- /bin/sh

# Port forward for local testing
kubectl port-forward service/typescript-app-service 8080:80 -n typescript-namespace
```

## 📊 Performance Tuning

### Resource Optimization
```yaml
# Adjust based on monitoring data
resources:
  requests:
    memory: "256Mi"  # Minimum required
    cpu: "250m"      # Minimum required
  limits:
    memory: "1Gi"    # Maximum allowed
    cpu: "1000m"     # Maximum allowed
```

### Scaling Configuration
```yaml
# Adjust based on traffic patterns
spec:
  minReplicas: 2        # Minimum pods
  maxReplicas: 20       # Maximum pods
  targetCPUUtilization: 60%    # Scale at 60% CPU
  targetMemoryUtilization: 70% # Scale at 70% Memory
```

## 📚 Additional Resources

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)

## 📞 Support

For deployment issues or security questions:
- **Documentation**: Check this README and inline comments
- **Logs**: Review application and system logs
- **Monitoring**: Check Grafana dashboards and Prometheus alerts
- **Support**: Contact DevSecOps team

---

**⚠️ Security Note**: This configuration implements defense-in-depth security practices. Regular security reviews and updates are recommended.
