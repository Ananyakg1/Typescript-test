# 🔧 Azure Individual Secrets Setup

The GitHub Actions workflow uses individual Azure secrets for authentication.

## 📋 Required GitHub Secrets

Set up the following individual secrets in your GitHub repository:

### Core Azure Authentication

```
AZURE_CLIENT_ID              # The application (client) ID of your service principal
AZURE_TENANT_ID              # Your Azure tenant ID
AZURE_CLIENT_SECRET          # The client secret of your service principal  
AZURE_SUBSCRIPTION_ID        # Your Azure subscription ID
```

### Additional Azure Resources

```
REGISTRY_LOGIN_SERVER        # Your ACR login server (e.g., myregistry.azurecr.io)
REGISTRY_USERNAME            # Your ACR username (usually same as AZURE_CLIENT_ID)
REGISTRY_PASSWORD            # Your ACR password (usually same as AZURE_CLIENT_SECRET)
AKS_CLUSTER_NAME            # Your AKS cluster name
AKS_RESOURCE_GROUP          # Your AKS resource group name
```

## 🚀 How to Get These Values

### 1. Create a Service Principal

```bash
# Login to Azure
az login

# Create service principal for GitHub Actions
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{your-subscription-id}
```

This outputs:
```json
{
  "appId": "12345678-1234-1234-1234-123456789012",           # Use as AZURE_CLIENT_ID
  "displayName": "github-actions-sp",
  "password": "your-generated-secret",                        # Use as AZURE_CLIENT_SECRET
  "tenant": "87654321-4321-4321-4321-210987654321"          # Use as AZURE_TENANT_ID
}
```

### 2. Get Subscription ID

```bash
az account show --query id --output tsv
```
Use this value for `AZURE_SUBSCRIPTION_ID`.

### 3. Get ACR Information

```bash
# Get ACR login server
az acr show --name <your-acr-name> --query loginServer --output tsv

# For ACR authentication, typically:
# REGISTRY_USERNAME = AZURE_CLIENT_ID
# REGISTRY_PASSWORD = AZURE_CLIENT_SECRET
```

### 4. Get AKS Information

```bash
# List your AKS clusters
az aks list --query "[].{name:name,resourceGroup:resourceGroup}" --output table
```

## 🔐 Setting Secrets in GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with its corresponding value:

| Secret Name | Value Source |
|-------------|-------------|
| `AZURE_CLIENT_ID` | `appId` from service principal creation |
| `AZURE_TENANT_ID` | `tenant` from service principal creation |
| `AZURE_CLIENT_SECRET` | `password` from service principal creation |
| `AZURE_SUBSCRIPTION_ID` | Output from `az account show` |
| `REGISTRY_LOGIN_SERVER` | Your ACR login server URL |
| `REGISTRY_USERNAME` | Usually same as `AZURE_CLIENT_ID` |
| `REGISTRY_PASSWORD` | Usually same as `AZURE_CLIENT_SECRET` |
| `AKS_CLUSTER_NAME` | Your AKS cluster name |
| `AKS_RESOURCE_GROUP` | Your AKS resource group |

## ✅ Verification

After setting up all secrets, the GitHub Actions workflow will:
1. Authenticate to Azure using the individual credentials
2. Log in to your Azure Container Registry
3. Build and scan the Docker image
4. Deploy to your AKS cluster

## 🔧 Troubleshooting

- **Authentication errors**: Verify that your service principal has the required permissions
- **ACR access denied**: Ensure the service principal has `AcrPush` role on the container registry
- **AKS access denied**: Ensure the service principal has `Azure Kubernetes Service Cluster User Role` on the AKS cluster

## 📚 Additional Resources

- [Azure Service Principals](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)
- [GitHub Actions Azure Login](https://github.com/Azure/login)
- [AKS Authentication](https://docs.microsoft.com/en-us/azure/aks/concepts-identity)
