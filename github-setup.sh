#!/bin/bash

# GitHub Repository Setup Script
# This script helps you push your code to the GitHub repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 GitHub Repository Setup Script${NC}"
echo -e "${BLUE}====================================${NC}"

# Configuration
REPO_URL="https://github.com/Ananyakg1/Typescript-test.git"
PROJECT_DIR="$(pwd)"

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

# Check if we're in the right directory
if [[ ! -f "Dockerfile" || ! -d "k8s" || ! -d ".github" ]]; then
    echo -e "${RED}❌ Please run this script from the project root directory${NC}"
    echo "Expected files: Dockerfile, k8s/, .github/"
    exit 1
fi

print_status 0 "Found project files in current directory"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed. Please install Git first.${NC}"
    exit 1
fi

print_status 0 "Git is installed"

# Check if this is already a git repository
if [ ! -d ".git" ]; then
    print_info "Initializing Git repository..."
    git init
    print_status $? "Git repository initialized"
else
    print_info "Git repository already exists"
fi

# Check if remote exists
if git remote get-url origin &> /dev/null; then
    CURRENT_REMOTE=$(git remote get-url origin)
    if [ "$CURRENT_REMOTE" != "$REPO_URL" ]; then
        print_warning "Remote origin exists but points to different URL: $CURRENT_REMOTE"
        read -p "Do you want to update the remote URL? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git remote set-url origin $REPO_URL
            print_status $? "Remote URL updated"
        fi
    else
        print_info "Remote origin already set correctly"
    fi
else
    print_info "Adding remote origin..."
    git remote add origin $REPO_URL
    print_status $? "Remote origin added"
fi

# Check for GitHub CLI (optional)
if command -v gh &> /dev/null; then
    print_info "GitHub CLI detected - you can use 'gh auth login' if needed"
else
    print_warning "GitHub CLI not found (optional). You may need to authenticate manually."
fi

# Show current status
print_info "Current Git status:"
git status --porcelain | head -10

# Ask user to review files
echo -e "\n${BLUE}📋 Files that will be committed:${NC}"
echo -e "${GREEN}✅ Dockerfile (secure multi-stage build)${NC}"
echo -e "${GREEN}✅ k8s/ (Kubernetes manifests with security)${NC}"
echo -e "${GREEN}✅ .github/workflows/deploy.yml (CI/CD pipeline)${NC}"
echo -e "${GREEN}✅ Security and documentation files${NC}"

echo -e "\n${YELLOW}⚠️  Before proceeding, make sure you have set up GitHub Secrets:${NC}"
echo "   - AZURE_CLIENT_ID"
echo "   - AZURE_CLIENT_SECRET"
echo "   - AZURE_SUSCRIPTION_ID"
echo "   - AZURE_TENANT_ID"
echo "   - REGISTRY_LOGIN_SERVER"
echo "   - REGISTRY_USERNAME"
echo "   - REGISTRY_PASSWORD"
echo "   - AKS_CLUSTER_NAME"
echo "   - AKS_RESOURCE_GROUP"

echo -e "\n${BLUE}📖 See GITHUB-SETUP.md for detailed instructions${NC}"

read -p "Do you want to continue with commit and push? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⏸️  Operation cancelled. Run the script again when ready.${NC}"
    exit 0
fi

# Add all files
print_info "Adding files to Git..."
git add .
print_status $? "Files added to Git staging"

# Show what will be committed
echo -e "\n${BLUE}📄 Files staged for commit:${NC}"
git diff --cached --name-only | head -20

# Create commit message
COMMIT_MESSAGE="feat: Add secure Docker configuration and Kubernetes deployment with CI/CD pipeline

🛡️ Security Features:
- Multi-stage secure Dockerfile with non-root user (UID 1001)
- Read-only root filesystem with security contexts
- Dropped Linux capabilities and privilege escalation prevention
- Comprehensive network policies for traffic isolation

🚀 CI/CD Pipeline:
- GitHub Actions workflow with Azure integration
- Trivy security scanning (CRITICAL/HIGH severity)
- Automated deployment to Azure Kubernetes Service
- Build ID-based image tagging for traceability

☸️ Kubernetes Configuration:
- Production-ready manifests with 3 replicas
- ClusterIP services for internal communication
- Horizontal Pod Autoscaler and Pod Disruption Budget
- ConfigMaps and Secrets management
- Health checks and monitoring integration

🔍 Security Scanning:
- Container vulnerability scanning with Trivy
- SARIF format output for GitHub Security tab
- Pipeline failure on critical vulnerabilities
- Secret detection and configuration validation

📊 Monitoring & Observability:
- Prometheus ServiceMonitor and alerting rules
- Comprehensive health checks (liveness, readiness, startup)
- Structured logging and metrics collection
- Security validation scripts

Built for Azure Container Registry and Azure Kubernetes Service deployment."

# Commit changes
print_info "Committing changes..."
git commit -m "$COMMIT_MESSAGE"
print_status $? "Changes committed successfully"

# Check current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
print_info "Current branch: $CURRENT_BRANCH"

# Push changes
print_info "Pushing to remote repository..."
if git push -u origin $CURRENT_BRANCH 2>&1; then
    print_status 0 "Code pushed successfully to GitHub!"
else
    # If push fails, try to handle authentication
    print_warning "Push failed. This might be due to authentication issues."
    echo -e "${BLUE}📝 Try one of these solutions:${NC}"
    echo "1. Set up GitHub Personal Access Token:"
    echo "   git remote set-url origin https://{TOKEN}@github.com/Ananyakg1/Typescript-test.git"
    echo ""
    echo "2. Use GitHub CLI authentication:"
    echo "   gh auth login"
    echo ""
    echo "3. Use SSH (if SSH key is set up):"
    echo "   git remote set-url origin git@github.com:Ananyakg1/Typescript-test.git"
    
    read -p "Do you want to try again? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push -u origin $CURRENT_BRANCH
        print_status $? "Code pushed successfully!"
    else
        echo -e "${YELLOW}⚠️  Push skipped. You can manually push later with: git push -u origin $CURRENT_BRANCH${NC}"
    fi
fi

# Show next steps
echo -e "\n${GREEN}🎉 Setup completed!${NC}"
echo -e "\n${BLUE}📋 Next Steps:${NC}"
echo "1. 🔗 Visit: https://github.com/Ananyakg1/Typescript-test"
echo "2. ⚙️  Go to Settings → Secrets and variables → Actions"
echo "3. 🔐 Add all required Azure secrets (see GITHUB-SETUP.md)"
echo "4. 🚀 Push another commit or create a PR to trigger the pipeline"
echo "5. 📊 Monitor the pipeline in the Actions tab"
echo "6. 🛡️  Check security scan results in the Security tab"

echo -e "\n${BLUE}🔍 Pipeline will trigger on:${NC}"
echo "   - Push to main or develop branches"
echo "   - Pull requests to main branch"

echo -e "\n${BLUE}📖 Documentation:${NC}"
echo "   - GITHUB-SETUP.md - GitHub secrets setup"
echo "   - k8s/README.md - Kubernetes deployment guide"
echo "   - SECURITY.md - Docker security documentation"

echo -e "\n${GREEN}✨ Your secure, production-ready pipeline is ready to go!${NC}"
