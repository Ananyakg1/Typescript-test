# GitHub Repository Setup Instructions

This guide will help you set up the GitHub secrets and push your code to the repository.

## 📋 Required GitHub Secrets

You need to set up the following secrets in your GitHub repository before the pipeline can run:

### Azure Authentication Secrets
```
AZURE_CLIENT_ID              # Your Azure Service Principal Client ID
AZURE_CLIENT_SECRET          # Your Azure Service Principal Secret
AZURE_SUSCRIPTION_ID         # Your Azure Subscription ID (note: keeping original spelling)
AZURE_TENANT_ID              # Your Azure Tenant ID
```

### Azure Container Registry Secrets
```
REGISTRY_LOGIN_SERVER        # Your ACR login server (e.g., myregistry.azurecr.io)
REGISTRY_USERNAME            # Your ACR username
REGISTRY_PASSWORD            # Your ACR password
```

### Azure Kubernetes Service Secrets
```
AKS_CLUSTER_NAME            # Your AKS cluster name
AKS_RESOURCE_GROUP          # Your AKS resource group name
```

## 🔧 Setting Up GitHub Secrets

1. Go to your GitHub repository: https://github.com/Ananyakg1/Typescript-test
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret with the exact name and value

## 🚀 Azure Service Principal Setup

If you haven't created an Azure Service Principal yet, run these commands in Azure CLI:

```bash
# Login to Azure
az login

# Create a service principal with contributor role
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{your-subscription-id} \
  --sdk-auth

# The output will give you the values for:
# - clientId (AZURE_CLIENT_ID)
# - clientSecret (AZURE_CLIENT_SECRET)
# - subscriptionId (AZURE_SUSCRIPTION_ID)
# - tenantId (AZURE_TENANT_ID)
```

## 🏗️ Azure Container Registry Setup

```bash
# Create or get ACR credentials
az acr credential show --name {your-acr-name}

# This will give you:
# - username (REGISTRY_USERNAME)
# - passwords (use password for REGISTRY_PASSWORD)
# - loginServer is {your-acr-name}.azurecr.io (REGISTRY_LOGIN_SERVER)
```

## 🎯 Azure Kubernetes Service Setup

```bash
# Get AKS information
az aks show --resource-group {your-rg} --name {your-aks-name}

# This will give you:
# - name (AKS_CLUSTER_NAME)
# - resourceGroup (AKS_RESOURCE_GROUP)
```

## 📤 Push Code to Repository

Run this script to initialize Git and push your code:

```bash
# Run the setup script
./github-setup.sh
```

Or manually:

```bash
# Navigate to your project directory
cd "c:\Users\KGAnanya\Downloads\sample-typescript-main-test\sample-typescript-main"

# Initialize git (if not already done)
git init

# Add the remote repository
git remote add origin https://github.com/Ananyakg1/Typescript-test.git

# Add all files
git add .

# Commit changes
git commit -m "feat: Add secure Docker configuration and Kubernetes deployment with CI/CD pipeline

- Multi-stage secure Dockerfile with non-root user
- Comprehensive Kubernetes manifests with security best practices
- GitHub Actions pipeline with Trivy security scanning
- Azure Container Registry and AKS deployment automation
- Network policies and resource constraints
- Monitoring and health checks configuration"

# Push to main branch
git push -u origin main
```

## 🔍 Verify Setup

After pushing the code:

1. **Check GitHub Actions**: Go to the **Actions** tab in your repository
2. **Monitor Pipeline**: The workflow should trigger automatically
3. **Review Logs**: Check both build and deploy job logs
4. **Security Scan**: Review Trivy scan results in the Security tab

## 🐛 Troubleshooting

### Common Issues:

1. **Azure Login Error**: 
   - Verify all Azure secrets are set correctly
   - Ensure Service Principal has proper permissions

2. **Docker Build Error**:
   - Check if Docker daemon is running in GitHub Actions (it should be by default)
   - Verify Dockerfile syntax

3. **Kubernetes Deployment Error**:
   - Ensure AKS cluster is running and accessible
   - Check if the namespace exists
   - Verify kubectl permissions

4. **Trivy Scan Failures**:
   - Review which vulnerabilities are found
   - Consider updating base images if needed

### Debug Commands:

If the pipeline fails, you can check these locally:

```bash
# Test Docker build
docker build -t test-image .

# Test Trivy scan
trivy image test-image

# Test Kubernetes manifests
kubectl apply --dry-run=client -f k8s/

# Validate YAML syntax
yamllint .github/workflows/deploy.yml
```

## 📞 Support

If you encounter issues:

1. **Check GitHub Actions logs** for detailed error messages
2. **Review Azure portal** for resource status
3. **Verify secrets** are set correctly in GitHub
4. **Test Azure CLI commands** locally with the same credentials

## 🎉 Success!

Once everything is set up correctly:

- Your application will build and scan automatically on every push
- Deployments to AKS will happen on pushes to `main` or `develop`
- Security scans will be visible in GitHub's Security tab
- Kubernetes resources will be created with security best practices

The pipeline includes comprehensive logging, so you can monitor every step of the process!
