# Getting Started with Prebid Server Infrastructure

Welcome! This guide will help you get started with deploying your Prebid Server infrastructure.

## What This Repository Provides

This is a complete, production-ready infrastructure setup that deploys:

1. **AWS Fargate** - Your primary service running 24/7
2. **GCP Cloud Run** - Your fallback service for AWS outages
3. **Route 53 Failover** - Automatic switching between AWS and GCP

## Choose Your Path

### 🚀 I want to deploy quickly (30 minutes)
→ Go to [docs/QUICKSTART.md](docs/QUICKSTART.md)

### 📚 I want to understand the architecture first
→ Go to [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

### ✅ I'm ready for production deployment
→ Go to [docs/DEPLOYMENT_CHECKLIST.md](docs/DEPLOYMENT_CHECKLIST.md)

### 🤔 I want to compare AWS vs GCP
→ Go to [docs/PLATFORM_COMPARISON.md](docs/PLATFORM_COMPARISON.md)

### 📖 I want a complete overview
→ Go to [docs/PROJECT_SUMMARY.md](docs/PROJECT_SUMMARY.md)

## Quick Links

| Resource | Description |
|----------|-------------|
| [README.md](README.md) | Complete deployment guide |
| [QUICKSTART.md](docs/QUICKSTART.md) | Fast deployment in 30 minutes |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Detailed architecture & diagrams |
| [DEPLOYMENT_CHECKLIST.md](docs/DEPLOYMENT_CHECKLIST.md) | Production checklist |
| [PLATFORM_COMPARISON.md](docs/PLATFORM_COMPARISON.md) | AWS vs GCP comparison |
| [PROJECT_SUMMARY.md](docs/PROJECT_SUMMARY.md) | Complete project overview |
| [CLOUDFRONT_SETUP.md](docs/CLOUDFRONT_SETUP.md) | CloudFront CDN setup guide |

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

## Deployment Overview

```
Step 1: Test Locally (5 min)
   ↓
Step 2: Deploy to AWS Fargate (15 min)
   ↓
Step 3: Deploy to GCP Cloud Run (10 min)
   ↓
Step 4: Configure DNS Failover (5 min)
   ↓
Step 5: Verify & Monitor
```

**Total Time**: ~35 minutes for complete multi-cloud setup

## What Gets Deployed

### AWS Infrastructure
- VPC with public/private subnets across 2 availability zones
- Application Load Balancer
- ECS Fargate cluster with 2-10 auto-scaling tasks
- CloudWatch monitoring and logging
- NAT Gateways for outbound connectivity

### GCP Infrastructure
- Cloud Run serverless service with 1-10 instances
- Global HTTP(S) Load Balancer
- Automatic logging and monitoring
- Service account with minimal permissions

### Cost
- **AWS**: ~$170/month (primary service, always running)
- **GCP**: ~$30-40/month (fallback service, mostly idle)
- **Total**: ~$200-210/month for multi-cloud high availability

## Need Help?

1. Check the [Troubleshooting section](README.md#troubleshooting) in README.md
2. Review [QUICKSTART.md](docs/QUICKSTART.md) for common issues
3. Check [DEPLOYMENT_CHECKLIST.md](docs/DEPLOYMENT_CHECKLIST.md) for prerequisites
4. Open an issue on GitHub

## Next Steps

1. **Start Here**: [QUICKSTART.md](docs/QUICKSTART.md)
2. **Understand Architecture**: [ARCHITECTURE.md](docs/ARCHITECTURE.md)
3. **Deploy to Production**: [DEPLOYMENT_CHECKLIST.md](docs/DEPLOYMENT_CHECKLIST.md)

---

**Ready to begin?** → [QUICKSTART.md](docs/QUICKSTART.md)
