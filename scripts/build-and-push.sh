#!/bin/bash
set -e

# Build and push Docker image to AWS ECR and GCP Container Registry

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
GCP_PROJECT_ID="${GCP_PROJECT_ID}"
IMAGE_NAME="prebid-server"
IMAGE_TAG="${IMAGE_TAG:-latest}"

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Error: AWS_ACCOUNT_ID environment variable is required"
    exit 1
fi

if [ -z "$GCP_PROJECT_ID" ]; then
    echo "Error: GCP_PROJECT_ID environment variable is required"
    exit 1
fi

# AWS ECR
echo "Building Docker image..."
cd "$(dirname "$0")/../docker"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

# Push to AWS ECR
echo ""
echo "Pushing to AWS ECR..."
AWS_ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ECR_URL}

# Create ECR repository if it doesn't exist
aws ecr describe-repositories --repository-names ${IMAGE_NAME} --region ${AWS_REGION} 2>/dev/null || \
    aws ecr create-repository --repository-name ${IMAGE_NAME} --region ${AWS_REGION}

docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${AWS_ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}
docker push ${AWS_ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}

echo "Image pushed to AWS ECR: ${AWS_ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

# Push to GCP Container Registry
echo ""
echo "Pushing to GCP Container Registry..."
GCP_GCR_URL="gcr.io/${GCP_PROJECT_ID}"
gcloud auth configure-docker

docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${GCP_GCR_URL}/${IMAGE_NAME}:${IMAGE_TAG}
docker push ${GCP_GCR_URL}/${IMAGE_NAME}:${IMAGE_TAG}

echo "Image pushed to GCP GCR: ${GCP_GCR_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

echo ""
echo "Docker images built and pushed successfully!"
echo "AWS ECR: ${AWS_ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "GCP GCR: ${GCP_GCR_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
