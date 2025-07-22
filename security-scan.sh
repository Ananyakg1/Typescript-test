#!/bin/bash

# Security scanning and validation script for OWASP Juice Shop container
# This script performs various security checks on the Docker image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

IMAGE_NAME="juice-shop-secure"
CONTAINER_NAME="juice-shop-security-test"

echo -e "${BLUE}🔍 Starting security validation for ${IMAGE_NAME}${NC}"

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Build the image
echo -e "${BLUE}🏗️  Building Docker image...${NC}"
docker build -t ${IMAGE_NAME} .
print_status $? "Docker image built successfully"

# 1. Check for root user
echo -e "${BLUE}👤 Checking user configuration...${NC}"
USER_CHECK=$(docker run --rm ${IMAGE_NAME} whoami)
if [ "$USER_CHECK" != "juiceshop" ]; then
    print_status 1 "Container should run as non-root user 'juiceshop'"
else
    print_status 0 "Container runs as non-root user: $USER_CHECK"
fi

# 2. Check for security vulnerabilities using Trivy (if available)
echo -e "${BLUE}🛡️  Scanning for vulnerabilities with Trivy...${NC}"
if command -v trivy &> /dev/null; then
    trivy image --severity HIGH,CRITICAL --exit-code 1 ${IMAGE_NAME}
    print_status $? "No HIGH/CRITICAL vulnerabilities found"
else
    print_warning "Trivy not installed. Skipping vulnerability scan. Install with: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin"
fi

# 3. Check image layers for secrets
echo -e "${BLUE}🔐 Scanning for secrets...${NC}"
if command -v docker &> /dev/null; then
    # Check image history for potential secrets
    HISTORY_CHECK=$(docker history ${IMAGE_NAME} --no-trunc --format "table {{.CreatedBy}}" | grep -i -E "(password|secret|key|token)" || true)
    if [ -n "$HISTORY_CHECK" ]; then
        print_warning "Potential secrets found in image history"
        echo "$HISTORY_CHECK"
    else
        print_status 0 "No obvious secrets found in image history"
    fi
fi

# 4. Check file permissions
echo -e "${BLUE}📁 Checking file permissions...${NC}"
PERM_CHECK=$(docker run --rm ${IMAGE_NAME} find /app -perm /002 -type f | head -5)
if [ -n "$PERM_CHECK" ]; then
    print_warning "World-writable files found:"
    echo "$PERM_CHECK"
else
    print_status 0 "No world-writable files found"
fi

# 5. Check for package vulnerabilities using npm audit
echo -e "${BLUE}📦 Checking Node.js dependencies for vulnerabilities...${NC}"
NPM_AUDIT=$(docker run --rm ${IMAGE_NAME} npm audit --audit-level=high --only=prod 2>/dev/null || true)
if echo "$NPM_AUDIT" | grep -q "found 0 vulnerabilities"; then
    print_status 0 "No high-severity npm vulnerabilities found"
else
    print_warning "NPM audit results:"
    echo "$NPM_AUDIT"
fi

# 6. Test health check
echo -e "${BLUE}❤️  Testing health check...${NC}"
docker run -d --name ${CONTAINER_NAME} ${IMAGE_NAME}
sleep 30

HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null || echo "unhealthy")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    print_status 0 "Health check is working"
else
    print_warning "Health check status: $HEALTH_STATUS"
fi

# Cleanup
docker stop ${CONTAINER_NAME} > /dev/null 2>&1 || true
docker rm ${CONTAINER_NAME} > /dev/null 2>&1 || true

# 7. Check resource constraints
echo -e "${BLUE}💾 Checking image size...${NC}"
IMAGE_SIZE=$(docker images ${IMAGE_NAME} --format "table {{.Size}}" | tail -1)
echo "Image size: $IMAGE_SIZE"

# 8. Security scan with Docker Scout (if available)
echo -e "${BLUE}🚨 Running Docker Scout scan...${NC}"
if docker scout version &> /dev/null; then
    docker scout cves ${IMAGE_NAME}
    print_status $? "Docker Scout scan completed"
else
    print_warning "Docker Scout not available. Consider enabling it for vulnerability scanning."
fi

# 9. Check for compliance with security standards
echo -e "${BLUE}📋 Checking security compliance...${NC}"

# Check if running as non-root
RUNNING_USER=$(docker run --rm ${IMAGE_NAME} id -u)
if [ "$RUNNING_USER" -eq 0 ]; then
    print_status 1 "Container should not run as root (UID 0)"
else
    print_status 0 "Container runs as non-root user (UID: $RUNNING_USER)"
fi

# Check for no-new-privileges
echo -e "${BLUE}🔒 Security recommendations:${NC}"
echo "- Use 'docker run --security-opt=no-new-privileges:true' to prevent privilege escalation"
echo "- Consider using 'docker run --read-only' for read-only root filesystem"
echo "- Use 'docker run --user 1001:1001' to explicitly set user"
echo "- Enable Docker Content Trust: export DOCKER_CONTENT_TRUST=1"
echo "- Run with resource limits: --memory=1g --cpus=1"

echo -e "${GREEN}🎉 Security validation completed!${NC}"
echo -e "${BLUE}📝 To run the container securely:${NC}"
echo "docker run -d \\"
echo "  --name juice-shop-secure \\"
echo "  --security-opt=no-new-privileges:true \\"
echo "  --user 1001:1001 \\"
echo "  --memory=1g \\"
echo "  --cpus=1 \\"
echo "  --read-only \\"
echo "  --tmpfs /tmp:noexec,nosuid,size=100m \\"
echo "  -p 3000:3000 \\"
echo "  ${IMAGE_NAME}"
