#!/bin/bash

# Default: also push :latest. Pass --no-latest to push only the version tag.
PUSH_LATEST=true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-latest)
            PUSH_LATEST=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--no-latest]"
            echo "  --no-latest    Push only the OPENVSCODE_VERSION tag, skip :latest"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--no-latest]"
            exit 1
            ;;
    esac
done

# Disable AWS CLI v2's interactive pager so JSON output doesn't pause the script
export AWS_PAGER=""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi

# Configuration
REPO_NAME="ai-arena-mdb-openvscode-linuxserver"
REGION="us-east-2"
PROFILE="Solution-Architects.User-979559056307"
DOCKERFILE="mdb-openvscode-linuxserver.dockerfile"
ACCOUNT_ID=$(aws sts get-caller-identity --profile $PROFILE --query Account --output text)
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Derive image tag from the OPENVSCODE_VERSION ARG default in the Dockerfile.
# Pushing the same tag overwrites the previous image in ECR (MUTABLE tags, default).
VERSION_TAG=$(grep -E '^ARG[[:space:]]+OPENVSCODE_VERSION=' "$DOCKERFILE" | head -n1 | cut -d'=' -f2)
if [ -z "$VERSION_TAG" ]; then
    echo "Error: Could not parse OPENVSCODE_VERSION from $DOCKERFILE"
    exit 1
fi

echo "Using AWS Account ID: $ACCOUNT_ID"
echo "Version tag (OPENVSCODE_VERSION): $VERSION_TAG"

echo "Creating ECR repository if it doesn't exist..."
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION --profile $PROFILE 2>/dev/null || \
aws ecr create-repository --repository-name $REPO_NAME --region $REGION --profile $PROFILE --tags Key=noreap,Value=true

echo "Logging into ECR..."
aws ecr get-login-password --region $REGION --profile $PROFILE | \
docker login --username AWS --password-stdin $ECR_URI

# Check if buildx is available and setup cross-platform builds
echo "Checking Docker buildx availability..."
mkdir -p logs
if docker buildx version >/dev/null 2>&1; then
    echo "Docker buildx found, setting up for cross-platform builds..."
    docker buildx create --name multiarch --driver docker-container --use 2>/dev/null || docker buildx use multiarch 2>/dev/null || docker buildx use default
    echo "Building Docker image for AMD64 architecture with buildx..."
    LOG_FILE="logs/build-$(date +%Y%m%d-%H%M%S).log"
    echo "Build logs will be saved to $LOG_FILE"
    docker buildx build --platform linux/amd64 -t $REPO_NAME -f $DOCKERFILE . --load 2>&1 | tee $LOG_FILE
else
    echo "Docker buildx not available, using regular docker build..."
    echo "Note: Building for native architecture. This may cause issues if deploying to different architecture."
    echo "To enable buildx support, ensure Docker Desktop is running with buildx enabled."
    LOG_FILE="logs/build-$(date +%Y%m%d-%H%M%S).log"
    echo "Build logs will be saved to $LOG_FILE"
    docker build -t $REPO_NAME -f $DOCKERFILE . 2>&1 | tee $LOG_FILE
fi

echo "Tagging image..."
docker tag $REPO_NAME:latest $ECR_URI/$REPO_NAME:$VERSION_TAG
if [ "$PUSH_LATEST" = "true" ]; then
    docker tag $REPO_NAME:latest $ECR_URI/$REPO_NAME:latest
fi

echo "Pushing images to ECR..."
docker push $ECR_URI/$REPO_NAME:$VERSION_TAG
if [ "$PUSH_LATEST" = "true" ]; then
    docker push $ECR_URI/$REPO_NAME:latest
fi

echo "Deploy complete!"
echo ""
echo "=== HELM DEPLOYMENT INFORMATION ==="
echo "Repository URI: $ECR_URI/$REPO_NAME"
if [ "$PUSH_LATEST" = "true" ]; then
    echo "Available tags: latest, $VERSION_TAG"
else
    echo "Available tags: $VERSION_TAG (--no-latest: skipped pushing :latest)"
fi
echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"
echo ""
echo "Full image paths:"
echo "  $ECR_URI/$REPO_NAME:$VERSION_TAG"
if [ "$PUSH_LATEST" = "true" ]; then
    echo "  $ECR_URI/$REPO_NAME:latest"
fi
