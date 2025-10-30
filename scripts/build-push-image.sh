#!/bin/bash
set -e

echo "Building Prebid Server Java Docker image..."
echo ""

TAG="${REGISTRY_URL}/${REPOSITORY_ID}/${IMAGE_NAME}"

# Build the image
cd "$(dirname "$0")/../docker"
docker buildx build -t ${TAG} .

echo ""
echo "Docker image built successfully!"

# Push to GCP GCR
if [ -n "$GCP_PROJECT_ID" ]; then
  echo ""
  echo "Pushing to GCP GCR..."
  gcloud auth configure-docker ${REGISTRY_URL}
  docker push ${TAG}
  echo "Image pushed to GCP GCR: ${TAG}"
fi

# Push to AWS ECR
# add conditional to enter only if AWS_ACCOUNT_ID and AWS_REGION are set
if [ -n "$AWS_ACCOUNT_ID" ] && [ -n "$AWS_REGION" ]; then
  echo ""
  echo "Pushing to AWS ECR..."
  aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY_URL}
  docker tag "${TAG}" "${REGISTRY_URL}/${REPOSITORY_ID}"
  docker push "${REGISTRY_URL}/${REPOSITORY_ID}"

  echo "Image pushed to AWS ECR: ${TAG}"
fi


echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Image pushed successfully!"
echo "Image: ${TAG}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

