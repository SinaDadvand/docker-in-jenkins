#!/bin/bash
# Comprehensive build script for Jenkins Docker Demo

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
IMAGE_NAME="jenkins-docker-demo"
VERSION=${APP_VERSION:-"1.0.0"}
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%Y%m%d-%H%M%S)}
REGISTRY=${DOCKER_REGISTRY:-"localhost:5000"}

print_status "Starting Docker build process..."
print_status "Image: ${IMAGE_NAME}"
print_status "Version: ${VERSION}"
print_status "Build Number: ${BUILD_NUMBER}"

# Step 1: Validate Docker is running
print_status "Checking Docker availability..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running or not accessible"
    exit 1
fi
print_success "Docker is available"

# Step 2: Clean up previous builds (optional)
print_status "Cleaning up old images..."
docker image prune -f --filter "label=description=Jenkins Docker Demo*" || true

# Step 3: Build production image
print_status "Building production Docker image..."
docker build \
    --file Dockerfile \
    --tag ${IMAGE_NAME}:${VERSION} \
    --tag ${IMAGE_NAME}:${BUILD_NUMBER} \
    --tag ${IMAGE_NAME}:latest \
    --build-arg NODE_ENV=production \
    --build-arg APP_VERSION=${VERSION} \
    --build-arg BUILD_NUMBER=${BUILD_NUMBER} \
    --label "build.number=${BUILD_NUMBER}" \
    --label "build.timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "git.commit=${GIT_COMMIT:-unknown}" \
    .

if [ $? -eq 0 ]; then
    print_success "Production image built successfully"
else
    print_error "Failed to build production image"
    exit 1
fi

# Step 4: Build development image
print_status "Building development Docker image..."
docker build \
    --file docker/Dockerfile.dev \
    --tag ${IMAGE_NAME}:dev \
    --build-arg NODE_ENV=development \
    .

if [ $? -eq 0 ]; then
    print_success "Development image built successfully"
else
    print_warning "Failed to build development image (non-critical)"
fi

# Step 5: Build test image
print_status "Building test Docker image..."
docker build \
    --file docker/Dockerfile.test \
    --tag ${IMAGE_NAME}:test \
    .

if [ $? -eq 0 ]; then
    print_success "Test image built successfully"
else
    print_warning "Failed to build test image (non-critical)"
fi

# Step 6: Run security scan (if tools available)
if command -v trivy &> /dev/null; then
    print_status "Running security scan with Trivy..."
    trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_NAME}:${VERSION}
    if [ $? -eq 0 ]; then
        print_success "Security scan passed"
    else
        print_warning "Security scan found issues"
    fi
else
    print_warning "Trivy not available - skipping security scan"
fi

# Step 7: Test the built image
print_status "Testing built image..."
CONTAINER_ID=$(docker run -d -p 3001:3000 ${IMAGE_NAME}:${VERSION})

if [ $? -eq 0 ]; then
    print_status "Container started with ID: ${CONTAINER_ID}"
    
    # Wait for application to start
    sleep 5
    
    # Test health endpoint
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        print_success "Health check passed"
    else
        print_error "Health check failed"
        docker logs ${CONTAINER_ID}
        docker stop ${CONTAINER_ID} && docker rm ${CONTAINER_ID}
        exit 1
    fi
    
    # Test main endpoint
    if curl -f http://localhost:3001/ > /dev/null 2>&1; then
        print_success "Application endpoint test passed"
    else
        print_error "Application endpoint test failed"
    fi
    
    # Cleanup test container
    docker stop ${CONTAINER_ID} && docker rm ${CONTAINER_ID}
    print_success "Test container cleaned up"
else
    print_error "Failed to start test container"
    exit 1
fi

# Step 8: Tag for registry (if specified)
if [ ! -z "${DOCKER_REGISTRY}" ] && [ "${DOCKER_REGISTRY}" != "localhost:5000" ]; then
    print_status "Tagging for registry: ${DOCKER_REGISTRY}"
    docker tag ${IMAGE_NAME}:${VERSION} ${DOCKER_REGISTRY}/${IMAGE_NAME}:${VERSION}
    docker tag ${IMAGE_NAME}:${VERSION} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
    print_success "Images tagged for registry"
fi

# Step 9: Display image information
print_status "Build completed successfully!"
print_status "Generated images:"
docker images | grep ${IMAGE_NAME}

# Step 10: Output build metadata
cat << EOF > build-metadata.json
{
  "image_name": "${IMAGE_NAME}",
  "version": "${VERSION}",
  "build_number": "${BUILD_NUMBER}",
  "build_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_commit": "${GIT_COMMIT:-unknown}",
  "docker_registry": "${DOCKER_REGISTRY}",
  "tags": [
    "${IMAGE_NAME}:${VERSION}",
    "${IMAGE_NAME}:${BUILD_NUMBER}",
    "${IMAGE_NAME}:latest"
  ]
}
EOF

print_success "Build metadata saved to build-metadata.json"
print_success "Docker build process completed successfully!"