#!/bin/bash
set -e

# Deploy GCP Cloud Run infrastructure
echo "Deploying GCP Cloud Run infrastructure..."

cd "$(dirname "$0")/../terraform/gcp"

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Apply deployment
read -p "Do you want to apply this plan? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply tfplan
    rm tfplan
    
    echo ""
    echo "GCP Cloud Run deployment completed!"
    echo "Getting outputs..."
    terraform output
else
    echo "Deployment cancelled"
    rm tfplan
    exit 1
fi
