# Prebid Server Infrastructure

Infrastructure as Code (IaC) for deploying a Java Prebid Server with high availability using AWS Fargate as the primary platform and Google Cloud Run as a fallback service in case of AWS outages.

## Architecture Overview

This infrastructure provides:

- **Primary Service**: AWS Fargate with auto-scaling and load balancing
- **Fallback Service**: Google Cloud Run for geographic redundancy and AWS outage protection
- **Containerized Deployment**: Docker-based deployment for consistency across platforms
- **Auto-scaling**: Automatic scaling based on CPU and memory utilization
- **Health Monitoring**: Built-in health checks and monitoring

## Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) configured with appropriate credentials
- [Docker](https://docs.docker.com/get-docker/)
- Maven (for building Java application)

### AWS Setup

1. Configure AWS credentials:
   ```bash
   aws configure
   ```

2. Set your AWS account ID:
   ```bash
   export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   export AWS_REGION=us-east-1
   ```

### GCP Setup

1. Authenticate with GCP:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. Set your GCP project:
   ```bash
   export GCP_PROJECT_ID=your-project-id
   gcloud config set project $GCP_PROJECT_ID
   ```

## Directory Structure

```
.
├── docker/                      # Docker configuration
│   ├── Dockerfile              # Multi-stage Docker build
│   └── docker-compose.yml      # Local development setup
├── scripts/                    # Deployment scripts
│   ├── build-and-push.sh      # Build and push Docker images
│   ├── deploy-aws.sh          # Deploy to AWS Fargate
│   └── deploy-gcp.sh          # Deploy to GCP Cloud Run
├── terraform/
│   ├── aws/                   # AWS Fargate infrastructure
│   │   ├── main.tf           # Main AWS resources
│   │   ├── variables.tf      # Input variables
│   │   ├── outputs.tf        # Output values
│   │   └── terraform.tfvars.example
│   └── gcp/                   # GCP Cloud Run infrastructure
│       ├── main.tf           # Main GCP resources
│       ├── variables.tf      # Input variables
│       ├── outputs.tf        # Output values
│       └── terraform.tfvars.example
└── README.md
```

## Deployment Guide

### Step 1: Choose Your Deployment Option

You have two options for deploying Prebid Server Java:

**Option A: Use the Official Prebuilt Image (Recommended)**
- Fastest deployment
- Maintained by Prebid.org
- Use `prebid/prebid-server-java:latest` in your terraform.tfvars

**Option B: Build from Source**
- Full control over the build
- Ability to customize
- Follow the build instructions below

### Step 2: Build and Push Docker Images (Option B only)

If building from source, push the image to both AWS ECR and GCP Container Registry:

```bash
# Set required environment variables
export AWS_ACCOUNT_ID=your-aws-account-id
export AWS_REGION=us-east-1
export GCP_PROJECT_ID=your-gcp-project-id
export IMAGE_TAG=v1.0.0

# Build and push images (builds Prebid Server Java from source)
./scripts/build-and-push.sh
```

**Note:** For production deployments using the prebuilt image, you can skip the build step and use `prebid/prebid-server-java:latest` directly in your Terraform configuration.

### Step 3: Deploy to AWS Fargate (Primary)

1. Navigate to the AWS Terraform directory:
   ```bash
   cd terraform/aws
   ```

2. Create a `terraform.tfvars` file from the example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` and update the values:
   - **Option A (Prebuilt):** `container_image = "prebid/prebid-server-java:latest"`
   - **Option B (Custom):** Use the ECR image URL from step 2
   - Other configuration as needed

4. Deploy using the script:
   ```bash
   ../../scripts/deploy-aws.sh
   ```

   Or manually:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. Note the ALB DNS name from the output:
   ```bash
   terraform output alb_dns_name
   ```

### Step 4: Deploy to GCP Cloud Run (Fallback)

1. Navigate to the GCP Terraform directory:
   ```bash
   cd terraform/gcp
   ```

2. Create a `terraform.tfvars` file from the example:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` and update the values:
   - `gcp_project_id`: Your GCP project ID
   - **Option A (Prebuilt):** `container_image = "prebid/prebid-server-java:latest"`
   - **Option B (Custom):** Use the GCR image URL from step 2
   - Other configuration as needed

4. Deploy using the script:
   ```bash
   ../../scripts/deploy-gcp.sh
   ```

   Or manually:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. Note the Cloud Run URL from the output:
   ```bash
   terraform output cloudrun_url
   ```

### Step 5: Deploy CloudFront CDN (Optional)

Add CloudFront in front of your ALB for global content delivery and enhanced security:

1. Navigate to the main Terraform directory:
   ```bash
   cd terraform
   ```

2. Edit `main.tf` and uncomment the CloudFront module:
   ```hcl
   module "aws-cloudfront" {
     source = "./aws-cloudfront"
     
     project_name = local.project_name
     alb_dns_name = module.aws-prebid-server.alb_dns_name
     enable_waf   = false  # Set to true for WAF protection
     
     depends_on = [module.aws-prebid-server]
   }
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. Get the CloudFront domain:
   ```bash
   terraform output cloudfront_domain_name
   ```

**Benefits of CloudFront**:
- Global edge locations for lower latency
- Built-in DDoS protection (AWS Shield Standard)
- Optional WAF for advanced security
- Automatic compression and caching
- HTTPS/SSL support with custom domains

See [terraform/aws-cloudfront/README.md](terraform/aws-cloudfront/README.md) for detailed configuration options.

## AWS Fargate Architecture

### Components

- **VPC**: Isolated network with public and private subnets across multiple AZs
- **Application Load Balancer**: Distributes traffic across ECS tasks
- **ECS Cluster**: Manages Fargate tasks
- **Fargate Tasks**: Runs containerized Prebid Server
- **Auto Scaling**: Scales based on CPU (70%) and Memory (80%) utilization
- **CloudWatch**: Centralized logging and monitoring
- **CloudFront (Optional)**: CDN for global content delivery and security

### Scaling Configuration

- **Min instances**: 2
- **Max instances**: 10
- **CPU target**: 70%
- **Memory target**: 80%

### Networking

- **Public subnets**: Host ALB for internet-facing traffic
- **Private subnets**: Host ECS tasks for enhanced security
- **NAT Gateways**: Enable outbound internet access for private subnets

## GCP Cloud Run Architecture

### Components

- **Cloud Run Service**: Fully managed serverless container platform
- **Global Load Balancer**: Distributes traffic globally
- **Service Account**: Manages permissions for the Cloud Run service
- **Health Checks**: Monitors service availability

### Scaling Configuration

- **Min instances**: 1 (cost-optimized for fallback)
- **Max instances**: 10
- **Concurrency**: 80 requests per container
- **CPU allocation**: 2 vCPUs
- **Memory**: 2 GiB

## Failover Strategy

### DNS-based Failover (Recommended)

Use Route 53 health checks and failover routing:

1. Create a Route 53 health check for the AWS ALB
2. Configure primary record pointing to AWS ALB
3. Configure secondary (failover) record pointing to Cloud Run
4. Route 53 will automatically failover to Cloud Run if AWS is unhealthy

### Manual Failover

If AWS experiences an outage:

1. Update DNS records to point to the Cloud Run URL
2. Monitor traffic switching to GCP
3. Cloud Run will automatically scale to handle the load

## Local Development

Run the Prebid Server locally using Docker Compose:

```bash
cd docker
docker-compose up
```

Access the server at `http://localhost:8080`

## Monitoring and Logs

### AWS

- **CloudWatch Logs**: `/ecs/prebid-server`
- **CloudWatch Metrics**: ECS service metrics
- **Container Insights**: Enabled for detailed metrics

### GCP

- **Cloud Logging**: Automatic logging for Cloud Run
- **Cloud Monitoring**: Service metrics and dashboards

## Health Checks

Both platforms monitor the `/status` endpoint:

- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Healthy threshold**: 2
- **Unhealthy threshold**: 3

## Cost Optimization

### AWS Fargate

- Use Fargate Spot for non-production environments
- Optimize task CPU/memory allocation
- Configure appropriate auto-scaling thresholds
- Use CloudWatch log retention policies

### GCP Cloud Run

- Keep min instances at 1 for fallback mode
- Enable CPU throttling when idle
- Use request-based pricing model
- Monitor and adjust concurrency settings

## Security Best Practices

1. **Network Security**:
   - ECS tasks run in private subnets
   - Security groups restrict traffic
   - Use VPC endpoints for AWS services

2. **IAM/Service Accounts**:
   - Principle of least privilege
   - Separate roles for execution and task
   - Regular credential rotation

3. **Container Security**:
   - Use official base images
   - Regular image scanning
   - Non-root user in containers
   - Multi-stage builds

4. **Secrets Management**:
   - Use AWS Secrets Manager or Parameter Store
   - Use GCP Secret Manager
   - Never hardcode secrets

## Troubleshooting

### AWS Fargate

Check ECS service events:
```bash
aws ecs describe-services --cluster prebid-server-cluster --services prebid-server-service
```

View CloudWatch logs:
```bash
aws logs tail /ecs/prebid-server --follow
```

### GCP Cloud Run

View Cloud Run logs:
```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=prebid-server" --limit 50
```

Check service status:
```bash
gcloud run services describe prebid-server --region us-central1
```

## Cleanup

### AWS

```bash
cd terraform/aws
terraform destroy
```

### GCP

```bash
cd terraform/gcp
terraform destroy
```

## Additional Resources

- [Prebid Server Documentation](https://docs.prebid.org/prebid-server/overview/prebid-server-overview.html)
- [AWS Fargate Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform Documentation](https://www.terraform.io/docs)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review AWS/GCP service health dashboards
3. Check CloudWatch/Cloud Logging for errors
4. Open an issue in this repository

## License

This infrastructure code is provided as-is for deploying Prebid Server.