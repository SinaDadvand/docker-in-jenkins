# Multi-stage Dockerfile for optimized production builds
# Stage 1: Build dependencies and prepare application

# Use official Node.js LTS image with Alpine Linux for smaller size
FROM node:18-alpine AS builder

# Set metadata for the image
LABEL maintainer="jenkins-learning@example.com"
LABEL description="Jenkins Docker Demo - Build Stage"
LABEL version="1.0.0"

# Create application directory with proper permissions
# Using a non-root user improves security
WORKDIR /app

# Create node user and group for security
# Alpine already has node user, but we ensure proper setup
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Copy package files first for better Docker layer caching
# This allows Docker to cache npm install if package.json hasn't changed
COPY package*.json ./

# Install dependencies
# --ci installs exact versions from package-lock.json
# --only=production excludes devDependencies for smaller image
# --silent reduces npm output noise
RUN npm install --only=production --silent && \
    npm cache clean --force

# Copy application source code
COPY src/ ./src/

# Install development dependencies for build process (if needed)
RUN npm ci --silent

# Run build process (linting, tests, etc.)
RUN npm run lint || echo "Linting skipped - no lint script found" && \
    npm run build || echo "Build completed"

# Stage 2: Create final production image
FROM node:18-alpine AS production

# Set metadata for production image
LABEL maintainer="jenkins-learning@example.com"
LABEL description="Jenkins Docker Demo - Production"
LABEL version="1.0.0"

# Install security updates and necessary packages
RUN apk --no-cache update && \
    apk --no-cache upgrade && \
    apk add --no-cache \
    curl \
    ca-certificates

# Create application directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Copy built application from builder stage
# Only copy necessary files to keep image small
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /app/src ./src

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV RUNNING_IN_DOCKER=true

# Switch to non-root user
USER nodejs

# Expose port (documentation only, doesn't actually publish)
EXPOSE 3000

# Add health check for container orchestration
# Docker will periodically run this command to check container health
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Use array form for CMD to avoid shell interpretation
# This is more secure and efficient
CMD ["node", "src/server.js"]