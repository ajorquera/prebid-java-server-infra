# Quick Start Guide

This guide will help you deploy the Prebid Server infrastructure to both AWS and GCP in under 30 minutes.

## Prerequisites Checklist

- [ ] AWS Account with appropriate permissions
- [ ] GCP Project with billing enabled
- [ ] Terraform installed (>= 1.0)
- [ ] AWS CLI configured (`aws configure`)
- [ ] gcloud CLI configured (`gcloud auth login`)
- [ ] Docker installed

## 5-Minute Local Test

Test Prebid Server Java locally before deploying to the cloud:

```bash
# Clone the repository
git clone https://github.com/ajorquera/prebid-java-server-infra.git
cd prebid-java-server-infra

# Start with Docker Compose (builds Prebid Server Java from source)
cd docker
docker-compose up

# Test the health endpoint
curl http://localhost:8080/status
```

Expected response:
```
200 OK
```

**Note:** The first build will take several minutes as it downloads and compiles Prebid Server Java. Subsequent builds will be faster.

Press `Ctrl+C` to stop the server.

## Deploy to AWS (Primary Service)

### Deployment Option

You can use either:
- **Option A (Recommended):** Official prebuilt image `prebid/prebid-server-java:latest`
- **Option B:** Build from source using the provided Dockerfile

### Step 1: Configure Terraform (Option A - Prebuilt Image)

```bash
cd terraform/aws
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars and set:
# container_image = "prebid/prebid-server-java:latest"
```

Skip to Step 3 below.

### Step 1-2: Build and Push (Option B - Custom Build)

Set Environment Variables:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1
export GCP_PROJECT_ID=your-gcp-project-id
export IMAGE_TAG=v1.0.0
```

### Step 2: Build and Push (Option B only)

```bash
cd /path/to/prebid-java-server-infra
./scripts/build-and-push.sh
```

This will:
- Build Prebid Server Java from source
- Create ECR and GCR repositories if needed
- Push images to both registries

**Save the image URLs** for the next step.

### Step 3: Configure and Deploy Terraform
- Output the ECR image URL

**Save the ECR image URL** - you'll need it in the next step.

### Step 3: Configure Terraform Variables

```bash
cd terraform/aws
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update:
```hcl
container_image = "YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/prebid-server:v1.0.0"
```

### Step 4: Deploy to AWS

```bash
# From terraform/aws directory
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted.

### Step 5: Get ALB URL

```bash
terraform output alb_dns_name
```

Test the deployment:
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://$ALB_DNS/status
```

**⏱️ Estimated Time: 10-15 minutes**

## Deploy to GCP (Fallback Service)

### Step 1: Set Environment Variables

```bash
export GCP_PROJECT_ID=your-project-id
export IMAGE_TAG=v1.0.0
```

### Step 2: Push Docker Image to GCR

If you didn't run the build-and-push script earlier:

```bash
cd docker
docker build -t prebid-server:${IMAGE_TAG} .

# Configure Docker for GCR
gcloud auth configure-docker

# Tag and push
docker tag prebid-server:${IMAGE_TAG} gcr.io/${GCP_PROJECT_ID}/prebid-server:${IMAGE_TAG}
docker push gcr.io/${GCP_PROJECT_ID}/prebid-server:${IMAGE_TAG}
```

**Save the GCR image URL** - you'll need it in the next step.

### Step 3: Configure Terraform Variables

```bash
cd terraform/gcp
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update:
```hcl
gcp_project_id  = "your-project-id"
container_image = "gcr.io/your-project-id/prebid-server:v1.0.0"
```

### Step 4: Deploy to GCP

```bash
# From terraform/gcp directory
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted.

### Step 5: Get Cloud Run URL

```bash
terraform output cloudrun_url
```

Test the deployment:
```bash
CLOUDRUN_URL=$(terraform output -raw cloudrun_url)
curl $CLOUDRUN_URL/status
```

**⏱️ Estimated Time: 5-10 minutes**

## Setup DNS Failover (Optional but Recommended)

This configures automatic failover from AWS to GCP.

### Prerequisites

- Domain name registered (e.g., example.com)
- Deployed AWS infrastructure
- Deployed GCP infrastructure

### Steps

```bash
cd terraform/failover
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
domain_name      = "example.com"
subdomain        = "prebid"  # Creates prebid.example.com
gcp_cloudrun_url = "prebid-server-xxxxx-uc.a.run.app"  # From GCP output
```

Deploy:
```bash
terraform init
terraform plan
terraform apply
```

Get nameservers:
```bash
terraform output route53_nameservers
```

Update your domain registrar to use these nameservers.

**⏱️ Estimated Time: 5 minutes + DNS propagation (up to 48 hours)**

## Verification

### Test AWS Endpoint

```bash
# Get ALB DNS
cd terraform/aws
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health
curl http://$ALB_DNS/status

# Test root
curl http://$ALB_DNS/
```

### Test GCP Endpoint

```bash
# Get Cloud Run URL
cd terraform/gcp
CLOUDRUN_URL=$(terraform output -raw cloudrun_url)

# Test health
curl $CLOUDRUN_URL/status

# Test root
curl $CLOUDRUN_URL/
```

### Test Failover (if configured)

```bash
# Test primary domain
curl http://prebid.example.com/status

# Should return AWS response normally
# During AWS outage, will automatically use GCP
```

## Monitoring

### AWS CloudWatch

```bash
# View logs
aws logs tail /ecs/prebid-server --follow

# View metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=prebid-server-service \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### GCP Cloud Logging

```bash
# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=prebid-server" --limit 50

# View metrics in console
gcloud run services describe prebid-server --region us-central1
```

## Cleanup

### Remove AWS Infrastructure

```bash
cd terraform/aws
terraform destroy
```

### Remove GCP Infrastructure

```bash
cd terraform/gcp
terraform destroy
```

### Remove Failover Configuration

```bash
cd terraform/failover
terraform destroy
```

### Remove Docker Images

```bash
# AWS ECR
aws ecr delete-repository --repository-name prebid-server --force

# GCP GCR
gcloud container images delete gcr.io/${GCP_PROJECT_ID}/prebid-server:${IMAGE_TAG}
```

## Troubleshooting

### Issue: Terraform fails with authentication error

**AWS:**
```bash
aws sts get-caller-identity  # Verify credentials
aws configure  # Reconfigure if needed
```

**GCP:**
```bash
gcloud auth list  # Verify authentication
gcloud auth login  # Re-authenticate if needed
```

### Issue: Docker build fails

```bash
# Clear Docker cache
docker system prune -a

# Rebuild
cd docker
docker build --no-cache -t prebid-server:latest .
```

### Issue: Health checks failing

```bash
# AWS - Check ECS service events
aws ecs describe-services \
  --cluster prebid-server-cluster \
  --services prebid-server-service

# GCP - Check Cloud Run logs
gcloud logging read "resource.type=cloud_run_revision" --limit 50
```

### Issue: Can't access ALB endpoint

- Wait 2-3 minutes after deployment for health checks to pass
- Verify security groups allow inbound traffic on port 80
- Check target group health in AWS Console

### Issue: Can't access Cloud Run endpoint

- Verify IAM permissions allow public access
- Check Cloud Run service status: `gcloud run services describe prebid-server`
- View logs for errors: `gcloud logging read "resource.type=cloud_run_revision"`

## Next Steps

1. **Custom Domain**: Configure your own domain with Route 53 failover
2. **HTTPS**: Add SSL/TLS certificates for secure connections
3. **Monitoring**: Set up CloudWatch/Cloud Monitoring dashboards
4. **Alerting**: Configure SNS/Email alerts for failures
5. **CI/CD**: Automate deployments with GitHub Actions or similar
6. **Scaling**: Adjust auto-scaling parameters based on traffic patterns
7. **Cost Optimization**: Use Fargate Spot, adjust instance sizes

## Support

- Documentation: See [README.md](../README.md) and [ARCHITECTURE.md](../docs/ARCHITECTURE.md)
- Issues: Open an issue on GitHub
- AWS Docs: https://docs.aws.amazon.com/fargate/
- GCP Docs: https://cloud.google.com/run/docs

## Estimated Costs

### Development/Testing
- AWS: ~$50-100/month
- GCP: ~$0-30/month (with free tier)
- **Total**: ~$50-130/month

### Production
- AWS: ~$140-500/month (depending on scale)
- GCP: ~$30-200/month (mostly idle, used for failover)
- **Total**: ~$170-700/month

*Costs vary based on region, traffic, and configuration*
