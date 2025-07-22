# 🔧 Azure Credentials Secret Setup

The GitHub Actions workflow now uses a single `AZURE_CREDENTIALS` secret instead of individual secrets for Azure authentication.

## 📋 Required GitHub Secrets

### Option 1: Single Azure Credentials Secret (Recommended)

Create **ONE** secret named `AZURE_CREDENTIALS` with this JSON format:

```json
{
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret", 
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"
}
```

### Additional Secrets (Still Required)

You still need these individual secrets:

```
REGISTRY_LOGIN_SERVER        # Your ACR login server (e.g., myregistry.azurecr.io)
REGISTRY_USERNAME            # Your ACR username
REGISTRY_PASSWORD            # Your ACR password
AKS_CLUSTER_NAME            # Your AKS cluster name
AKS_RESOURCE_GROUP          # Your AKS resource group name
```

## 🚀 How to Create AZURE_CREDENTIALS Secret

### Method 1: Using Azure CLI (Easiest)

```bash
# Login to Azure
az login

# Create service principal and get credentials in correct format
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{your-subscription-id} \
  --sdk-auth
```

This command outputs the exact JSON format you need for the `AZURE_CREDENTIALS` secret!

### Method 2: Manual JSON Creation

If you already have the individual values, create this JSON:

```json
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "your-secret-value",
  "subscriptionId": "87654321-4321-4321-4321-210987654321",
  "tenantId": "11111111-2222-3333-4444-555555555555"
}
```

## 📝 Setting Up in GitHub

1. Go to: https://github.com/Ananyakg1/Typescript-test/settings/secrets/actions
2. Click **"New repository secret"**
3. Name: `AZURE_CREDENTIALS`
4. Value: The complete JSON from above
5. Click **"Add secret"**

## ✅ Verify Your Secrets

After adding all secrets, you should have:

- ✅ `AZURE_CREDENTIALS` (JSON format)
- ✅ `REGISTRY_LOGIN_SERVER`
- ✅ `REGISTRY_USERNAME`
- ✅ `REGISTRY_PASSWORD`
- ✅ `AKS_CLUSTER_NAME`
- ✅ `AKS_RESOURCE_GROUP`

## 🎯 Next Steps

After updating the secret:
1. The pipeline should now work with the Azure login
2. Push any change to trigger the pipeline
3. Monitor the Actions tab for successful execution

This change fixes the Azure login error you encountered!
