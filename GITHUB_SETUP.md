# 🚀 GitHub Actions Setup Guide

## Repository Setup Complete! ✅

Your code has been successfully pushed to: **https://github.com/Ananyakg1/Typescript-test.git**

## 📋 Required GitHub Secrets Configuration

Before the pipeline can run, you need to configure the following secrets in your GitHub repository:

### 🔧 How to Add Secrets:

1. Go to your repository: https://github.com/Ananyakg1/Typescript-test
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each secret below

### 🔑 Azure Credentials (9 Separate Secrets)

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AZURE_CLIENT_ID` | Azure Service Principal App ID | `12345678-1234-1234-1234-123456789abc` |
| `AZURE_CLIENT_SECRET` | Azure Service Principal Secret | `your-client-secret-value` |
| `AZURE_SUSCRIPTION_ID` | Azure Subscription ID | `12345678-1234-1234-1234-123456789abc` |
| `AZURE_TENANT_ID` | Azure Tenant ID | `12345678-1234-1234-1234-123456789abc` |
| `REGISTRY_LOGIN_SERVER` | ACR Login Server | `yourregistry.azurecr.io` |
| `REGISTRY_USERNAME` | ACR Username | `yourregistry` |
| `REGISTRY_PASSWORD` | ACR Password | `your-acr-password` |
| `AKS_CLUSTER_NAME` | AKS Cluster Name | `your-aks-cluster` |
| `AKS_RESOURCE_GROUP` | AKS Resource Group | `your-resource-group` |

## 🏗️ Pipeline Overview

The GitHub Actions workflow (`.github/workflows/deploy.yml`) will:

### **Job 1: Build & Security Scan**
- ✅ Build Docker image with unique tag (run-number + SHA)
- ✅ Install Trivy security scanner manually
- ✅ Run comprehensive security scanning:
  - Table format for console output
  - SARIF format for GitHub Security tab
  - Critical/High severity focus
  - Ignore unfixed vulnerabilities
- ✅ Push to Azure Container Registry
- ✅ Upload scan artifacts

### **Job 2: Deploy to AKS**  
- ✅ Deploy to `typescript-namespace`
- ✅ Update image with new tag
- ✅ Apply all Kubernetes manifests
- ✅ Verify deployment health
- ✅ Run post-deployment tests

## 🎯 Pipeline Triggers

The pipeline will automatically run on:
- **Push to `main` branch** → Full build, scan, and deploy
- **Push to `develop` branch** → Full build, scan, and deploy  
- **Pull Request to `main`** → Build and scan only (no deployment)

## 🔍 Security Features

### **Trivy Integration:**
- **Manual installation** + **aquasecurity/trivy-action@0.28.0**
- **Exit code 1** for critical vulnerabilities (fails pipeline)
- **SARIF upload** to GitHub Security tab
- **Ignore unfixed** vulnerabilities for actionable results

### **Kubernetes Security:**
- Non-root containers (UID 1001)
- Read-only root filesystem
- Network policies
- Resource limits
- Security contexts
- Pod disruption budgets

## 🚀 How to Run the Pipeline

### **Option 1: Automatic Trigger**
1. Make any code change
2. Commit and push to `main` or `develop`:
   ```bash
   git add .
   git commit -m "Update application"
   git push origin main
   ```

### **Option 2: Manual Trigger**  
1. Go to **Actions** tab in your repo
2. Select **Build, Scan & Deploy to AKS**
3. Click **Run workflow**

## 📊 Monitoring Pipeline Execution

### **GitHub Actions UI:**
- Go to **Actions** tab: https://github.com/Ananyakg1/Typescript-test/actions
- Click on any workflow run to see detailed logs

### **Security Scan Results:**
- **Security tab**: View Trivy SARIF results
- **Artifacts**: Download detailed scan reports
- **Console logs**: See table-format vulnerability output

### **Deployment Verification:**
```bash
# Check deployment status
kubectl get deployments -n typescript-namespace

# View pods
kubectl get pods -n typescript-namespace

# Check services  
kubectl get services -n typescript-namespace

# View logs
kubectl logs -f deployment/typescript-app-deployment -n typescript-namespace
```

## 🛠️ Local Development Commands

### **Build and Test Locally:**
```bash
# Build Docker image
docker build -t typescript-local .

# Run security scan
./security-scan.sh

# Deploy to Kubernetes (if you have local cluster)
./k8s/deploy.sh

# Validate security
./k8s/security-validation.sh
```

## 📁 Key Files Created

```
├── .github/workflows/deploy.yml          # Complete CI/CD pipeline
├── Dockerfile                            # Secure multi-stage build  
├── .dockerignore                          # Security-focused exclusions
├── k8s/
│   ├── deployment.yaml                   # Secure K8s deployment
│   ├── service.yaml                      # ClusterIP services
│   ├── configmap.yaml                    # App configuration
│   ├── secret.yaml                       # Secure secrets
│   ├── network-policy.yaml               # Network security
│   ├── hpa.yaml                          # Auto-scaling
│   ├── pdb.yaml                          # High availability
│   └── monitoring.yaml                   # Prometheus monitoring
├── docker-compose.secure.yml             # Local secure stack
├── nginx.conf                            # Security-hardened proxy
├── security-scan.sh                      # Local security validation
└── SECURITY.md                           # Security documentation
```

## ⚠️ Important Notes

### **First Run:**
- The first pipeline run may take longer due to:
  - Docker layer caching initialization
  - Trivy database download
  - Kubernetes resource creation

### **Image Tags:**
- Each build creates a unique tag: `{run-number}-{git-sha}`
- Example: `123-abc12345` (run 123, commit abc12345)
- This ensures no tag conflicts and perfect traceability

### **Security Scanning:**
- Pipeline **WILL FAIL** if critical vulnerabilities are found
- This is intentional for security-first approach
- Fix vulnerabilities or temporarily adjust severity levels if needed

### **Namespace:**
- All resources deploy to `typescript-namespace`
- Namespace is created automatically if it doesn't exist

## 🎉 Next Steps

1. **Add GitHub Secrets** (required before first run)
2. **Push a small change** to trigger the pipeline
3. **Monitor the Actions tab** for execution progress
4. **Check Security tab** for vulnerability reports
5. **Verify deployment** in your AKS cluster

## 🆘 Troubleshooting

### **Pipeline Fails on Security Scan:**
- Check the Trivy output in pipeline logs
- Review uploaded artifacts for detailed vulnerability report
- Update dependencies or adjust Dockerfile if needed

### **Deployment Fails:**
- Verify AKS cluster credentials and permissions
- Check namespace exists and has proper RBAC
- Review Kubernetes resource specifications

### **Authentication Issues:**
- Verify all 9 GitHub secrets are correctly configured
- Test Azure CLI authentication separately
- Check ACR permissions for push/pull operations

---

🎊 **Congratulations!** Your enterprise-grade, security-focused CI/CD pipeline is ready to run! 

The pipeline combines Docker security best practices, comprehensive vulnerability scanning with Trivy, and production-ready Kubernetes deployment with advanced security controls.
