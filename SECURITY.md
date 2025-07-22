# Secure Docker Configuration for OWASP Juice Shop

This repository contains a security-hardened Docker configuration for the OWASP Juice Shop application, implementing multiple layers of security controls and best practices.

## 🛡️ Security Features Implemented

### 1. **Multi-Stage Build**
- Separate build and runtime stages to minimize attack surface
- Development dependencies removed from production image
- Reduced image size and vulnerability exposure

### 2. **Base Image Security**
- **Specific version pinning**: Uses `node:18.20.4-alpine3.20` (no `latest` tags)
- **Alpine Linux**: Minimal attack surface with security updates
- **Version-locked dependencies**: All system packages use specific versions

### 3. **Non-Root User Implementation**
- **Dedicated user**: `juiceshop` (UID: 1001, GID: 1001)
- **Proper ownership**: All files owned by non-root user
- **Security context**: Prevents privilege escalation

### 4. **File System Security**
- **Minimal permissions**: Files set to 644, directories to 755
- **No world-writable files**: Prevents unauthorized modifications
- **Proper file ownership**: All application files owned by `juiceshop` user

### 5. **Dependency Security**
- **NPM audit integration**: Automatic vulnerability fixes during build
- **Production-only dependencies**: Development packages excluded
- **Cache clearing**: NPM caches cleaned to reduce image size

### 6. **Runtime Security**
- **Resource limits**: Memory and CPU constraints
- **Security options**: `no-new-privileges`, read-only capabilities
- **Health checks**: Comprehensive application health monitoring
- **Signal handling**: Proper process management with `dumb-init`

### 7. **Network Security**
- **Non-privileged ports**: Application runs on port 3000
- **Reverse proxy**: Nginx with security headers and rate limiting
- **SSL/TLS**: HTTPS termination with modern cipher suites

## 📋 Application Details

- **Language**: Node.js (TypeScript)
- **Framework**: Express.js with Angular frontend
- **Dependencies**: 50+ production packages with security patches
- **Database**: MongoDB/SQLite
- **Application Files**: 
  - Backend: TypeScript/JavaScript in `/lib`, `/routes`, `/models`
  - Frontend: Angular application in `/frontend/dist`
  - Static assets: `/data/static`
  - Configuration: `/config`

## 🚀 Quick Start

### Build and Run Securely

```bash
# Build the secure image
docker build -t juice-shop-secure .

# Run with security options
docker run -d \
  --name juice-shop-secure \
  --security-opt=no-new-privileges:true \
  --user 1001:1001 \
  --memory=1g \
  --cpus=1 \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=100m \
  -p 3000:3000 \
  juice-shop-secure
```

### Using Docker Compose (Recommended)

```bash
# Run with full security stack including Nginx proxy
docker-compose -f docker-compose.secure.yml up -d
```

## 🔍 Security Validation

### Automated Security Scanning

Run the comprehensive security validation script:

```bash
./security-scan.sh
```

This script performs:
- ✅ User privilege checks
- ✅ Vulnerability scanning (Trivy, Docker Scout)
- ✅ File permission auditing
- ✅ NPM dependency scanning
- ✅ Health check validation
- ✅ Security compliance verification

### Manual Security Checks

#### 1. Verify Non-Root User
```bash
docker run --rm juice-shop-secure whoami
# Should output: juiceshop
```

#### 2. Check File Permissions
```bash
docker run --rm juice-shop-secure ls -la /app
# Verify ownership is juiceshop:nodejs
```

#### 3. Test Health Check
```bash
docker run -d --name test-container juice-shop-secure
sleep 30
docker inspect --format='{{.State.Health.Status}}' test-container
# Should output: healthy
```

#### 4. Vulnerability Scanning
```bash
# Using Trivy
trivy image juice-shop-secure

# Using Docker Scout
docker scout cves juice-shop-secure
```

## 🔧 Configuration Files

### Core Files
- **`Dockerfile`**: Multi-stage secure build configuration
- **`.dockerignore`**: Comprehensive exclusion list for security
- **`docker-compose.secure.yml`**: Production-ready compose file
- **`nginx.conf`**: Security-hardened reverse proxy configuration

### Security Tools
- **`security-scan.sh`**: Automated security validation script
- **`SECURITY.md`**: This security documentation

## 🛡️ Security Best Practices Implemented

### Container Security
- [x] Non-root user execution (UID 1001)
- [x] Minimal base image (Alpine Linux)
- [x] Multi-stage builds
- [x] No secrets in image layers
- [x] Proper signal handling
- [x] Resource constraints
- [x] Health checks
- [x] Security labels

### Network Security
- [x] Non-privileged ports
- [x] Network isolation
- [x] Rate limiting
- [x] SSL/TLS termination
- [x] Security headers
- [x] CORS configuration

### Application Security
- [x] Dependency vulnerability fixes
- [x] Production-only builds
- [x] Environment hardening
- [x] Log security
- [x] File permission hardening

## 🚨 Security Considerations

### Known Limitations
- **Application Purpose**: This is an intentionally vulnerable application for training
- **Read-Only Filesystem**: May need adjustment based on application requirements
- **Resource Limits**: Adjust memory/CPU limits based on load requirements

### Production Recommendations
1. **Secret Management**: Use Docker secrets or external secret management
2. **Image Scanning**: Integrate with CI/CD pipeline vulnerability scanning
3. **Monitoring**: Implement runtime security monitoring
4. **Updates**: Regularly update base images and dependencies
5. **Backup**: Secure backup strategy for persistent data

## 🔗 Security Resources

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Container Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Container Security Guide](https://csrc.nist.gov/publications/detail/sp/800-190/final)

## 📞 Security Contact

For security issues or questions:
- **Email**: security@company.com
- **Issue Tracker**: GitHub Issues with `security` label

---

**⚠️ Important**: This configuration secures the container infrastructure. The OWASP Juice Shop application itself contains intentional vulnerabilities for educational purposes.
