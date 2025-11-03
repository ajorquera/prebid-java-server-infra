# Prebid Server Infrastructure

Welcome! This guide will help you get started with deploying your Prebid Server infrastructure.

## What This Repository Provides

This is a complete, production-ready infrastructure setup that deploys:

1. **AWS Fargate** - Your primary service running 24/7
2. **GCP Cloud Run** - Your fallback service for AWS outages

## Choose Your Path

### 🚀 I want to deploy quickly (5 minutes)
→ Go to [docs/QUICKSTART.md](#quickstart)

### 📚 I want to understand the architecture first
→ Go to [docs/ARCHITECTURE.md](./ARCHITECTURE.md)

### 🤔 I want to compare AWS vs GCP
→ Go to [docs/PLATFORM_COMPARISON.md](./PLATFORM_COMPARISON.md)

## Quickstart
```
terraform init
terraform apply
```

### Variables
* **project_name**        - A unique name for your deployment (used in resource names as prefix)
* **gcp_project_id**      - Your GCP project ID
* **gcp_region**          - GCP region for Cloud Run (default: us-central1)
* **aws_region**          - AWS region for Fargate (default: us-east-1)
* **repository_id**       - ECR repository ID for Docker images
* **image_name**          - Docker image name (default: pbs)
* **ssl_certificate_arn** - ARN of your AWS ACM SSL certificate
* **domain_names**        - List of domain names for the load balancers


## Directory Structure

```
├── docker/                     
│   ├── Dockerfile               
│   └── docker-compose.yml       
├── scripts/                    
│   ├── build-push-image.sh      # Build and push Docker images to the appropriate repository
├── terraform/
│   ├── main.tf                 
│   ├── aws-prebid-server/                  
│   │   ├── ...
│   └── gcp-prebid-server/      
│       ├── ...
|
└── README.md
```


## 5-Minute Test

Try the application locally right now:

```bash
cd docker
docker-compose up
```

Then visit: http://localhost:8080/status

You should see:
```json
{
  "status": "UP",
  "service": "prebid-server",
  "timestamp": 1234567890
}
```

## Prerequisites

Before deploying to the cloud, ensure you have:

- [ ] AWS Account with admin access
- [ ] GCP Project with billing enabled
- [ ] Terraform installed (>= 1.0)
- [ ] AWS CLI configured
- [ ] gcloud CLI configured
- [ ] Docker installed


## What Gets Deployed

### AWS Infrastructure
- VPC with public/private subnets across 2 availability zones
- Application Load Balancer
- ECS Fargate cluster auto-scaling tasks (1 by default)
- CloudWatch monitoring and logging
- NAT Gateways for outbound connectivity

### GCP Infrastructure
- Cloud Run serverless service (0 instances by default)
- Global HTTP(S) Load Balancer
- Automatic logging and monitoring
- Service account with minimal permissions
