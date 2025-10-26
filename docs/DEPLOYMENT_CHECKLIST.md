# Deployment Checklist

Use this checklist to ensure a successful deployment of the Prebid Server infrastructure.

## Pre-Deployment Checklist

### AWS Prerequisites
- [ ] AWS Account created with admin access
- [ ] AWS CLI installed and configured (`aws --version`)
- [ ] AWS credentials configured (`aws sts get-caller-identity`)
- [ ] Appropriate IAM permissions for:
  - [ ] VPC creation
  - [ ] ECS/Fargate management
  - [ ] ALB creation
  - [ ] CloudWatch access
  - [ ] ECR access

### GCP Prerequisites
- [ ] GCP Project created with billing enabled
- [ ] gcloud CLI installed (`gcloud --version`)
- [ ] Authenticated with GCP (`gcloud auth list`)
- [ ] Required APIs enabled:
  - [ ] Cloud Run API
  - [ ] Container Registry API
  - [ ] Compute Engine API

### Development Tools
- [ ] Terraform installed (>= 1.0) (`terraform --version`)
- [ ] Docker installed and running (`docker --version`)
- [ ] Git installed (`git --version`)
- [ ] curl or wget for testing

### Repository Setup
- [ ] Repository cloned locally
- [ ] All files present (24 files expected)
- [ ] Scripts are executable (`chmod +x scripts/*.sh`)

## AWS Deployment Checklist

### 1. Docker Image Preparation
- [ ] Navigate to docker directory
- [ ] Build Docker image successfully
- [ ] ECR repository created
- [ ] Image pushed to ECR
- [ ] ECR image URL recorded: `_________________________`

### 2. Terraform Configuration
- [ ] Navigate to `terraform/aws/`
- [ ] Copy `terraform.tfvars.example` to `terraform.tfvars`
- [ ] Update `container_image` with ECR URL
- [ ] Review and customize other variables:
  - [ ] `aws_region` (default: us-east-1)
  - [ ] `desired_count` (default: 2)
  - [ ] `min_capacity` (default: 2)
  - [ ] `max_capacity` (default: 10)

### 3. Terraform Deployment
- [ ] Run `terraform init` successfully
- [ ] Run `terraform validate` successfully
- [ ] Run `terraform plan` and review changes
- [ ] Run `terraform apply` and confirm with 'yes'
- [ ] Deployment completed without errors

### 4. Verification
- [ ] ALB DNS name obtained from output
- [ ] Wait 2-3 minutes for health checks
- [ ] Test health endpoint: `curl http://ALB_DNS/status`
- [ ] Response returns `{"status":"UP"}`
- [ ] Test root endpoint: `curl http://ALB_DNS/`
- [ ] Check CloudWatch logs: `aws logs tail /ecs/prebid-server`
- [ ] Verify auto-scaling group created
- [ ] Verify tasks are running

### 5. Documentation
- [ ] ALB DNS recorded: `_________________________`
- [ ] ECS Cluster name recorded: `_________________________`
- [ ] CloudWatch log group recorded: `_________________________`

## GCP Deployment Checklist

### 1. Docker Image Preparation
- [ ] GCR repository access configured
- [ ] Image tagged for GCR
- [ ] Image pushed to GCR
- [ ] GCR image URL recorded: `_________________________`

### 2. Terraform Configuration
- [ ] Navigate to `terraform/gcp/`
- [ ] Copy `terraform.tfvars.example` to `terraform.tfvars`
- [ ] Update `gcp_project_id`
- [ ] Update `container_image` with GCR URL
- [ ] Review and customize other variables:
  - [ ] `gcp_region` (default: us-central1)
  - [ ] `min_instances` (default: 1)
  - [ ] `max_instances` (default: 10)

### 3. Terraform Deployment
- [ ] Run `terraform init` successfully
- [ ] Run `terraform validate` successfully
- [ ] Run `terraform plan` and review changes
- [ ] Run `terraform apply` and confirm with 'yes'
- [ ] Deployment completed without errors

### 4. Verification
- [ ] Cloud Run URL obtained from output
- [ ] Test health endpoint: `curl CLOUDRUN_URL/status`
- [ ] Response returns `{"status":"UP"}`
- [ ] Test root endpoint: `curl CLOUDRUN_URL/`
- [ ] Check Cloud Logging for application logs
- [ ] Verify service is running
- [ ] Verify auto-scaling is configured

### 5. Documentation
- [ ] Cloud Run URL recorded: `_________________________`
- [ ] Service name recorded: `_________________________`
- [ ] Load balancer IP recorded: `_________________________`

## DNS Failover Setup (Optional)

### Prerequisites
- [ ] Domain name available
- [ ] AWS infrastructure deployed
- [ ] GCP infrastructure deployed
- [ ] Cloud Run URL extracted (without https://)

### Configuration
- [ ] Navigate to `terraform/failover/`
- [ ] Copy `terraform.tfvars.example` to `terraform.tfvars`
- [ ] Update `domain_name`
- [ ] Update `subdomain` (optional)
- [ ] Update `gcp_cloudrun_url` (remove https://)

### Deployment
- [ ] Run `terraform init` successfully
- [ ] Run `terraform plan` and review changes
- [ ] Run `terraform apply` and confirm with 'yes'
- [ ] Nameservers obtained from output
- [ ] Domain registrar updated with Route 53 nameservers
- [ ] DNS propagation confirmed (can take up to 48 hours)

### Verification
- [ ] Test domain: `curl http://your-domain.com/status`
- [ ] Health check working
- [ ] Primary (AWS) serving traffic
- [ ] Failover configured correctly

## Post-Deployment Tasks

### Monitoring Setup
- [ ] AWS CloudWatch dashboard created
- [ ] GCP Cloud Monitoring dashboard created
- [ ] CloudWatch alarms configured
- [ ] Log retention policies set
- [ ] Cost alerts configured

### Security Review
- [ ] Security groups reviewed
- [ ] IAM roles follow least privilege
- [ ] Service accounts have minimal permissions
- [ ] No hardcoded secrets in configuration
- [ ] SSL/TLS certificates configured (if using HTTPS)

### Documentation
- [ ] All endpoints documented
- [ ] Deployment process documented
- [ ] Team members have access
- [ ] Runbook created for common issues
- [ ] Failover procedure documented

### Testing
- [ ] Load testing performed
- [ ] Failover tested manually
- [ ] Health checks validated
- [ ] Auto-scaling tested
- [ ] Logs verified for both platforms

## Ongoing Maintenance

### Weekly Tasks
- [ ] Review CloudWatch/Cloud Logging logs
- [ ] Check auto-scaling activity
- [ ] Review costs and optimize
- [ ] Verify health checks passing

### Monthly Tasks
- [ ] Update Docker images with security patches
- [ ] Review and update Terraform configurations
- [ ] Test failover mechanism
- [ ] Review and optimize costs
- [ ] Backup Terraform state files

### Quarterly Tasks
- [ ] Review architecture for improvements
- [ ] Update documentation
- [ ] Perform disaster recovery drill
- [ ] Review and update security policies

## Rollback Plan

If deployment fails or issues occur:

### AWS Rollback
1. [ ] Navigate to `terraform/aws/`
2. [ ] Run `terraform destroy` to remove resources
3. [ ] Review error logs
4. [ ] Fix configuration issues
5. [ ] Redeploy when ready

### GCP Rollback
1. [ ] Navigate to `terraform/gcp/`
2. [ ] Run `terraform destroy` to remove resources
3. [ ] Review error logs
4. [ ] Fix configuration issues
5. [ ] Redeploy when ready

### Emergency Contacts
- AWS Support: `_________________________`
- GCP Support: `_________________________`
- Team Lead: `_________________________`
- On-call Engineer: `_________________________`

## Success Criteria

Deployment is considered successful when:

- [ ] AWS Fargate service is running with desired task count
- [ ] GCP Cloud Run service is running
- [ ] Health checks passing on both platforms
- [ ] Both endpoints respond to HTTP requests
- [ ] Auto-scaling is functional
- [ ] Logs are being collected
- [ ] No errors in CloudWatch/Cloud Logging
- [ ] Failover mechanism configured (if applicable)
- [ ] All documentation updated
- [ ] Team trained on operation and troubleshooting

## Notes

Document any issues encountered during deployment:

```
Date: _______________
Issue: _______________________________________________
Resolution: __________________________________________
Time to Resolve: _____________________________________
```

## Sign-off

Deployment completed by: `_________________________`
Date: `_________________________`
Verified by: `_________________________`
Date: `_________________________`
