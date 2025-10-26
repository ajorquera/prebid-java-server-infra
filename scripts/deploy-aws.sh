#!/bin/bash
set -e

# Deploy AWS Fargate infrastructure
echo "Deploying AWS Fargate infrastructure..."

cd "$(dirname "$0")/../terraform/aws"

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
    echo "AWS Fargate deployment completed!"
    echo "Getting outputs..."
    terraform output
else
    echo "Deployment cancelled"
    rm tfplan
    exit 1
fi
