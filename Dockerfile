# Multi-stage build for security and optimization
# Use specific, security-patched base images

# Stage 1: Build stage
FROM node:18.20.4-alpine3.20 AS builder

# Set working directory
WORKDIR /app

# Create non-root user early
RUN addgroup -g 1001 -S nodejs && \
    adduser -S juiceshop -u 1001

# Install build dependencies with security considerations
RUN apk add --no-cache \
    python3=~3.12 \
    make=~4.4 \
    g++=~13.2 \
    && rm -rf /var/cache/apk/*

# Copy package files with proper ownership
COPY --chown=juiceshop:nodejs package*.json ./
COPY --chown=juiceshop:nodejs frontend/package*.json ./frontend/

# Install dependencies with npm audit fix for security patches
RUN npm ci --only=production --no-optional && \
    npm audit fix --audit-level=high && \
    cd frontend && \
    npm ci --only=production --no-optional --legacy-peer-deps && \
    npm audit fix --audit-level=high

# Copy source code
COPY --chown=juiceshop:nodejs . .

# Build the application
RUN npm run build:server && \
    npm run build:frontend

# Remove development dependencies and clear npm cache
RUN npm prune --production && \
    npm cache clean --force && \
    cd frontend && \
    npm prune --production && \
    npm cache clean --force

# Stage 2: Runtime stage
FROM node:18.20.4-alpine3.20 AS runtime

# Install security updates
RUN apk upgrade --no-cache && \
    apk add --no-cache \
    dumb-init=~1.2 \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S juiceshop -u 1001

# Set working directory
WORKDIR /app

# Create necessary directories with proper permissions
RUN mkdir -p /app/logs /app/uploads /app/data && \
    chown -R juiceshop:nodejs /app

# Copy built application from builder stage
COPY --from=builder --chown=juiceshop:nodejs /app/build ./build
COPY --from=builder --chown=juiceshop:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=juiceshop:nodejs /app/frontend/dist ./frontend/dist
COPY --from=builder --chown=juiceshop:nodejs /app/frontend/node_modules ./frontend/node_modules
COPY --from=builder --chown=juiceshop:nodejs /app/data ./data
COPY --from=builder --chown=juiceshop:nodejs /app/views ./views
COPY --from=builder --chown=juiceshop:nodejs /app/swagger.yml ./swagger.yml
COPY --from=builder --chown=juiceshop:nodejs /app/config ./config
COPY --from=builder --chown=juiceshop:nodejs /app/package.json ./package.json

# Security hardening
RUN chmod -R 755 /app && \
    chmod -R 644 /app/build && \
    chmod -R 644 /app/frontend/dist && \
    chmod -R 644 /app/data && \
    chmod -R 644 /app/views && \
    chmod -R 644 /app/config && \
    chmod 644 /app/package.json /app/swagger.yml && \
    find /app -name "*.js" -exec chmod 644 {} \; && \
    find /app -name "*.json" -exec chmod 644 {} \;

# Set security-focused environment variables
ENV NODE_ENV=production \
    NODE_OPTIONS="--max-old-space-size=1024 --max-http-header-size=8192" \
    NPM_CONFIG_AUDIT_LEVEL=high \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_UPDATE_NOTIFIER=false

# Expose port (non-privileged)
EXPOSE 3000

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "const http = require('http'); \
    const options = { hostname: 'localhost', port: 3000, path: '/rest/admin/application-version', timeout: 5000 }; \
    const req = http.get(options, (res) => { \
    if (res.statusCode === 200 || res.statusCode === 401) process.exit(0); \
    else process.exit(1); \
    }); \
    req.on('error', () => process.exit(1)); \
    req.on('timeout', () => { req.destroy(); process.exit(1); });"

# Switch to non-root user
USER juiceshop

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Start the application with security considerations
CMD ["node", "--trace-warnings", "--unhandled-rejections=strict", "build/app.js"]

# Security labels
LABEL maintainer="security@company.com" \
      version="13.3.0" \
      description="Secure OWASP Juice Shop container" \
      security.scan="enabled" \
      security.non-root="true" \
      security.healthcheck="enabled"
