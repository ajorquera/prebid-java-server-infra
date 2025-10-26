# Project Summary

## Overview

This repository contains complete Infrastructure as Code (IaC) for deploying a highly available Java Prebid Server using:
- **AWS Fargate** as the primary service
- **Google Cloud Run** as the fallback service
- **Route 53 DNS failover** for automatic switching

## What's Included

### 📁 Repository Structure

```
prebid-java-server-infra/
├── README.md                          # Main documentation
├── .gitignore                         # Git ignore rules
│
├── docker/                            # Docker configuration
│   ├── Dockerfile                     # Multi-stage build for Java app
│   ├── docker-compose.yml            # Local development setup
│   ├── pom.xml                       # Maven configuration
│   └── src/main/java/                # Sample Spring Boot application
│       └── org/prebid/server/
│           ├── PrebidServerApplication.java
│           ├── HealthController.java
│           └── resources/
│               └── application.properties
│
├── scripts/                           # Deployment automation
│   ├── build-and-push.sh             # Build & push to ECR/GCR
│   ├── deploy-aws.sh                 # Deploy AWS infrastructure
│   └── deploy-gcp.sh                 # Deploy GCP infrastructure
│
├── terraform/                         # Infrastructure as Code
│   ├── aws/                          # AWS Fargate configuration
│   │   ├── main.tf                   # 468 lines of AWS resources
│   │   ├── variables.tf              # Configurable parameters
│   │   ├── outputs.tf                # Deployment outputs
│   │   └── terraform.tfvars.example  # Configuration template
│   │
│   ├── gcp/                          # GCP Cloud Run configuration
│   │   ├── main.tf                   # 194 lines of GCP resources
│   │   ├── variables.tf              # Configurable parameters
│   │   ├── outputs.tf                # Deployment outputs
│   │   └── terraform.tfvars.example  # Configuration template
│   │
│   └── failover/                     # DNS Failover configuration
│       ├── main.tf                   # Route 53 failover setup
│       ├── variables.tf              # DNS parameters
│       ├── outputs.tf                # DNS outputs
│       └── terraform.tfvars.example  # Configuration template
│
└── docs/                             # Comprehensive documentation
    ├── QUICKSTART.md                 # 5-minute deployment guide
    ├── ARCHITECTURE.md               # Detailed architecture diagrams
    ├── DEPLOYMENT_CHECKLIST.md       # Production deployment checklist
    └── PLATFORM_COMPARISON.md        # AWS vs GCP comparison
```

### 📊 Statistics

- **Total Files**: 27
- **Terraform Lines**: ~1,100+ lines
- **Java Code**: Spring Boot application with health endpoints
- **Documentation**: 47KB across 5 markdown files
- **Scripts**: 3 bash deployment scripts

## Key Features

### 🏗️ AWS Fargate Infrastructure

**Resources Created** (terraform/aws/):
- VPC with public and private subnets across 2 AZs
- Internet Gateway and 2 NAT Gateways
- Application Load Balancer (ALB)
- ECS Cluster with Fargate launch type
- ECS Service with auto-scaling (2-10 tasks)
- Security Groups for ALB and ECS tasks
- CloudWatch Log Groups
- IAM Roles for task execution and task runtime
- Auto-scaling policies (CPU 70%, Memory 80%)

**Configuration Options**:
- Customizable CPU/Memory (default: 1 vCPU, 2 GB)
- Configurable scaling thresholds
- Multi-AZ deployment
- Container Insights enabled

### ☁️ GCP Cloud Run Infrastructure

**Resources Created** (terraform/gcp/):
- Cloud Run service with auto-scaling
- Global Load Balancer
- Backend service with health checks
- Service Account with minimal permissions
- Network Endpoint Group (NEG)
- Forwarding rules

**Configuration Options**:
- CPU/Memory limits (default: 2 vCPU, 2 GiB)
- Concurrency settings (default: 80)
- Min/Max instances (default: 1-10)
- Request timeout (default: 300s)

### 🔄 DNS Failover

**Features**:
- Route 53 health checks on AWS ALB
- Automatic failover to GCP on AWS failure
- Primary/Secondary routing policy
- Configurable health check intervals

**Failover Time**: ~2-4 minutes total
- Detection: 90 seconds (3 × 30s checks)
- DNS propagation: 60-120 seconds

### 🐳 Docker Configuration

**Dockerfile Features**:
- Multi-stage build (builder + runtime)
- Java 17 with Eclipse Temurin
- Maven dependency caching
- Non-root user for security
- Built-in health checks
- Optimized for container environments

**Sample Application**:
- Spring Boot 3.1.5
- RESTful endpoints (/, /status)
- Health check integration
- Actuator for monitoring
- Ready for production use

## Quick Deployment

### 1️⃣ Local Testing (2 minutes)

```bash
cd docker
docker-compose up
curl http://localhost:8080/status
```

### 2️⃣ AWS Deployment (15 minutes)

```bash
# Build and push image
export AWS_ACCOUNT_ID=your-account-id
./scripts/build-and-push.sh

# Deploy infrastructure
cd terraform/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your ECR image URL
terraform init && terraform apply
```

### 3️⃣ GCP Deployment (10 minutes)

```bash
# Deploy infrastructure
cd terraform/gcp
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCR image URL
terraform init && terraform apply
```

### 4️⃣ DNS Failover (5 minutes)

```bash
cd terraform/failover
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with domain and Cloud Run URL
terraform init && terraform apply
```

## Cost Estimates

### AWS Fargate (Primary - Always Running)
```
Baseline Configuration (2 tasks, 24/7):
├── Compute (vCPU + Memory): $72/month
├── NAT Gateways (2 AZs): $66/month
├── Load Balancer: $20/month
├── Data Transfer: $10-20/month
└── Total: ~$170/month
```

### GCP Cloud Run (Fallback - Mostly Idle)
```
Minimal Configuration (1 instance):
├── Compute (mostly idle): $10-20/month
├── Load Balancer: $18/month
├── Requests (within free tier): $0/month
└── Total: ~$30-40/month
```

**Combined Monthly Cost**: ~$200-210/month for high availability

## Architecture Highlights

### Multi-Cloud Redundancy

```
                     User Request
                          ↓
                    Route 53 DNS
                    (Health Checks)
                          ↓
              ┌───────────┴───────────┐
              ↓                       ↓
         AWS Primary              GCP Fallback
    (Fargate 2-10 tasks)      (Cloud Run 1-10 inst)
              ↓                       ↓
         Application              Application
```

### AWS Architecture

- **High Availability**: Multi-AZ deployment (us-east-1a, us-east-1b)
- **Security**: Private subnets for tasks, public subnets for ALB
- **Scalability**: Auto-scaling based on CPU/Memory metrics
- **Monitoring**: CloudWatch Logs and Container Insights

### GCP Architecture

- **Serverless**: Fully managed Cloud Run platform
- **Global**: Load balancer with global anycast IP
- **Efficient**: Scales to zero when not in use (with min_instances=1)
- **Fast**: Sub-second auto-scaling

## Documentation

### 📖 Available Guides

1. **README.md** (9KB)
   - Project overview
   - Prerequisites
   - Step-by-step deployment
   - Monitoring and troubleshooting

2. **QUICKSTART.md** (8KB)
   - Fastest path to deployment
   - 5-minute local test
   - Deployment checklists
   - Common issues and solutions

3. **ARCHITECTURE.md** (14KB)
   - Detailed architecture diagrams
   - Network flow explanations
   - Failover strategy
   - Cost breakdown
   - Disaster recovery plans

4. **DEPLOYMENT_CHECKLIST.md** (8KB)
   - Pre-deployment prerequisites
   - Step-by-step deployment checklist
   - Verification procedures
   - Post-deployment tasks
   - Sign-off template

5. **PLATFORM_COMPARISON.md** (9KB)
   - AWS vs GCP feature comparison
   - Performance characteristics
   - Cost analysis
   - Use case recommendations
   - Migration strategies

## Security Features

### AWS Security
- ✅ Tasks run in private subnets
- ✅ Security groups restrict traffic
- ✅ IAM roles with least privilege
- ✅ VPC Flow Logs enabled
- ✅ CloudWatch encryption

### GCP Security
- ✅ Service accounts with minimal permissions
- ✅ Cloud Run IAM controls
- ✅ Automatic encryption at rest and in transit
- ✅ VPC Service Controls compatible
- ✅ Binary authorization support

### Best Practices Implemented
- ✅ No hardcoded credentials
- ✅ Non-root containers
- ✅ Multi-stage Docker builds
- ✅ Secrets management integration points
- ✅ Network segmentation

## Monitoring & Observability

### AWS CloudWatch
- Service metrics (CPU, Memory, Request Count)
- Container Insights (detailed container metrics)
- Log aggregation in `/ecs/prebid-server`
- Custom dashboards support

### GCP Cloud Operations
- Automatic logging to Cloud Logging
- Cloud Monitoring metrics
- Cloud Trace integration
- Error Reporting

## Testing & Validation

### Health Checks
- **Endpoint**: `/status`
- **Response**: `{"status":"UP","service":"prebid-server","timestamp":...}`
- **Interval**: 30 seconds
- **Timeout**: 5 seconds

### Load Testing Ready
- Infrastructure supports horizontal scaling
- Auto-scaling configured for traffic spikes
- Multi-AZ and multi-cloud deployment

## Next Steps After Deployment

1. **Configure Custom Domain**: Set up your domain with Route 53
2. **Enable HTTPS**: Add SSL/TLS certificates
3. **Set Up Monitoring**: Create CloudWatch/Cloud Monitoring dashboards
4. **Configure Alerts**: Set up notifications for failures
5. **Implement CI/CD**: Automate deployments
6. **Load Testing**: Validate scaling behavior
7. **Backup Strategy**: Configure backup procedures

## Support & Maintenance

### Included
- ✅ Comprehensive documentation
- ✅ Example configurations
- ✅ Deployment scripts
- ✅ Troubleshooting guides

### Community
- GitHub Issues for questions
- Documentation updates via PRs
- Platform-specific support channels

## License

This infrastructure code is provided as-is for deploying Prebid Server.

## Credits

Built with:
- Terraform for Infrastructure as Code
- AWS Fargate for primary compute
- GCP Cloud Run for fallback compute
- Spring Boot for the application framework
- Docker for containerization

---

**Ready to deploy?** Start with [QUICKSTART.md](docs/QUICKSTART.md)!
