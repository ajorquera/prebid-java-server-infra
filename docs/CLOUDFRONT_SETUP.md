# CloudFront CDN Setup Guide

This guide walks you through setting up Amazon CloudFront as a CDN for your Prebid Server infrastructure.

## What is CloudFront?

Amazon CloudFront is a Content Delivery Network (CDN) that distributes your content globally through a network of edge locations. When used with Prebid Server, it provides:

- **Global Edge Locations**: 400+ locations worldwide for lower latency
- **DDoS Protection**: Built-in AWS Shield Standard
- **Enhanced Security**: Optional AWS WAF integration
- **Cost Savings**: Reduced bandwidth costs from your origin (ALB)
- **Better Performance**: Compression and optimized routing

## Prerequisites

Before setting up CloudFront, ensure you have:

1. ✅ AWS Prebid Server infrastructure deployed (ALB + ECS Fargate)
2. ✅ Terraform installed and configured
3. ✅ AWS credentials with CloudFront permissions
4. (Optional) ACM certificate for custom domain (must be in us-east-1)

## Quick Setup (Default Configuration)

### Step 1: Enable CloudFront Module

Edit `terraform/main.tf` and uncomment the CloudFront module:

```hcl
module "aws-cloudfront" {
  source = "./aws-cloudfront"

  project_name = local.project_name
  alb_dns_name = module.aws-prebid-server.alb_dns_name
  
  depends_on = [module.aws-prebid-server]
}
```

### Step 2: Apply Configuration

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 3: Get CloudFront URL

```bash
terraform output cloudfront_domain_name
```

Example output: `d1234567890abc.cloudfront.net`

### Step 4: Test CloudFront

```bash
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)
curl https://${CLOUDFRONT_URL}/status
```

You should see CloudFront headers in the response:
```
X-Cache: Miss from cloudfront
X-Amz-Cf-Id: ...
Via: 1.1 ... (CloudFront)
```

✅ **Done!** Your CloudFront distribution is now live.

---

## Advanced Configurations

### Configuration 1: Enable WAF Protection

Add WAF for enhanced security with DDoS protection and threat detection:

```hcl
module "aws-cloudfront" {
  source = "./aws-cloudfront"

  project_name = local.project_name
  alb_dns_name = module.aws-prebid-server.alb_dns_name
  enable_waf   = true  # Enable WAF
  
  depends_on = [module.aws-prebid-server]
}
```

**WAF Features**:
- AWS Managed Rules for common threats
- Rate limiting (2000 req/5min per IP)
- Protection against known bad inputs

**Cost**: Additional ~$8-10/month

### Configuration 2: Custom Domain with SSL

Use your own domain with CloudFront:

#### Prerequisites
1. ACM certificate in us-east-1 region
2. Domain name configured

#### Step 2.1: Create ACM Certificate

```bash
# Certificate MUST be in us-east-1 for CloudFront
aws acm request-certificate \
  --domain-name prebid.example.com \
  --validation-method DNS \
  --region us-east-1
```

#### Step 2.2: Validate Certificate

Add the DNS validation records provided by ACM to your domain's DNS.

#### Step 2.3: Configure CloudFront with Custom Domain

```hcl
module "aws-cloudfront" {
  source = "./aws-cloudfront"

  project_name        = local.project_name
  alb_dns_name        = module.aws-prebid-server.alb_dns_name
  ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
  domain_names        = ["prebid.example.com"]
  
  depends_on = [module.aws-prebid-server]
}
```

#### Step 2.4: Update DNS

Create a CNAME record pointing your domain to CloudFront:

```
prebid.example.com  CNAME  d1234567890abc.cloudfront.net
```

Or use Route 53 alias record (recommended):
```hcl
resource "aws_route53_record" "cloudfront" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "prebid.example.com"
  type    = "A"

  alias {
    name                   = module.aws-cloudfront.cloudfront_domain_name
    zone_id                = module.aws-cloudfront.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
```

### Configuration 3: All Edge Locations (Global)

Use all CloudFront edge locations worldwide:

```hcl
module "aws-cloudfront" {
  source = "./aws-cloudfront"

  project_name = local.project_name
  alb_dns_name = module.aws-prebid-server.alb_dns_name
  price_class  = "PriceClass_All"  # Use all edge locations
  
  depends_on = [module.aws-prebid-server]
}
```

**Price Classes**:
- `PriceClass_100`: US, Canada, Europe (lowest cost)
- `PriceClass_200`: Above + Asia, South Africa
- `PriceClass_All`: All edge locations (highest cost)

### Configuration 4: Custom Caching

Adjust caching behavior for your use case:

```hcl
module "aws-cloudfront" {
  source = "./aws-cloudfront"

  project_name = local.project_name
  alb_dns_name = module.aws-prebid-server.alb_dns_name
  
  # Caching configuration
  default_ttl = 3600    # 1 hour default cache
  max_ttl     = 86400   # 24 hours max cache
  min_ttl     = 0       # No minimum cache
  
  depends_on = [module.aws-prebid-server]
}
```

**Note**: Prebid Server is highly dynamic. Excessive caching may return stale bids. Use with caution.

---

## Verification and Testing

### 1. Check Distribution Status

```bash
aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='CloudFront distribution for prebid-server'].{Id:Id,Status:Status,DomainName:DomainName}"
```

Wait for status to be "Deployed" (can take 5-15 minutes).

### 2. Test Health Endpoint

```bash
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)
curl -I https://${CLOUDFRONT_URL}/status
```

Expected response:
```
HTTP/2 200
x-cache: Miss from cloudfront
x-amz-cf-id: ...
via: 1.1 ... (CloudFront)
```

### 3. Test Caching Behavior

Make the same request twice:
```bash
curl -I https://${CLOUDFRONT_URL}/status
curl -I https://${CLOUDFRONT_URL}/status
```

First request: `X-Cache: Miss from cloudfront`
Second request: `X-Cache: Hit from cloudfront` (if caching is enabled)

### 4. Test from Multiple Locations

Use a service like [GlobalPing](https://www.jsdelivr.com/globalping) to test from different locations:

```bash
curl "https://api.globalping.io/v1/measurements" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "type": "http",
    "target": "https://'${CLOUDFRONT_URL}'/status",
    "locations": [
      {"country": "US"},
      {"country": "GB"},
      {"country": "JP"}
    ]
  }'
```

---

## Monitoring

### CloudWatch Metrics

CloudFront automatically publishes metrics to CloudWatch:

1. Go to CloudWatch Console
2. Select "CloudFront" namespace
3. View metrics:
   - Requests
   - BytesDownloaded
   - 4xxErrorRate
   - 5xxErrorRate

### Access Logs

Access logs are stored in S3:

```bash
LOGS_BUCKET=$(terraform output -raw cloudfront_logs_bucket)
aws s3 ls s3://${LOGS_BUCKET}/cloudfront/
```

### WAF Metrics (if enabled)

View WAF metrics in CloudWatch:
- AllowedRequests
- BlockedRequests
- CountedRequests

---

## Troubleshooting

### Issue: Distribution Not Accessible

**Symptoms**: 502/503 errors from CloudFront

**Solutions**:
1. Check ALB health: `terraform output alb_dns_name`
2. Verify ECS tasks are running
3. Check security groups allow CloudFront IPs
4. Wait for distribution to finish deploying

### Issue: Cache Not Working as Expected

**Symptoms**: Always getting "Miss from cloudfront"

**Solutions**:
1. Verify caching is enabled: Check `default_ttl` > 0
2. Check origin cache-control headers
3. Review cache policy configuration
4. Remember: Prebid Server is mostly dynamic content

### Issue: Custom Domain Not Working

**Symptoms**: SSL errors or domain not resolving

**Solutions**:
1. Verify certificate is in us-east-1 region
2. Check certificate is validated and issued
3. Verify domain name in CloudFront matches certificate
4. Check DNS CNAME/alias record is correct
5. Wait for DNS propagation (up to 48 hours)

### Issue: High Costs

**Symptoms**: Unexpected CloudFront charges

**Solutions**:
1. Review traffic patterns in CloudWatch
2. Consider using PriceClass_100 instead of PriceClass_All
3. Check if you have unnecessary invalidations
4. Review data transfer metrics

---

## Cost Estimation

### Without WAF

**Assumptions**:
- 10 million requests/month
- 1 GB average response size
- PriceClass_100 (US, Canada, Europe)

**Estimated Costs**:
- Requests: 10M × $0.0075/10K = $7.50
- Data Transfer: 10GB × $0.085/GB = $0.85
- **Total**: ~$8.35/month

### With WAF

**Additional WAF Costs**:
- Web ACL: $5.00/month
- Rules: 3 × $1.00/month = $3.00/month
- Requests: 10M × $0.60/1M = $6.00/month
- **Total WAF**: ~$14/month

**Grand Total with WAF**: ~$22.35/month

---

## Integration with Failover

When using CloudFront with the failover module, you have options:

### Option A: CloudFront for AWS Only

```
Route 53 → CloudFront → ALB (AWS Primary)
              ↓ (on failover)
         Cloud Run (GCP Secondary)
```

Failover bypasses CloudFront and goes directly to GCP.

### Option B: No CloudFront for Failover

```
Route 53 → ALB (AWS Primary)
         ↓ (on failover)
         Cloud Run (GCP Secondary)
```

Simpler setup, no CloudFront benefits on either platform.

---

## Best Practices

1. **Start Simple**: Deploy without WAF first, add it later if needed
2. **Monitor Costs**: Review CloudWatch metrics and AWS Cost Explorer
3. **Use Default Caching**: Don't over-cache dynamic Prebid content
4. **Enable Compression**: Always keep compression enabled
5. **Use PriceClass_100**: Start with US/Canada/Europe, expand if needed
6. **Test Thoroughly**: Verify from multiple geographic locations
7. **Plan for Custom Domains**: Request certificates in us-east-1
8. **Review Logs**: Regularly check CloudFront access logs

---

## Cleanup

To remove CloudFront:

```bash
cd terraform

# Comment out the CloudFront module in main.tf
# Then run:
terraform apply

# Or destroy everything:
terraform destroy
```

**Note**: CloudFront distributions take 15-30 minutes to fully delete.

---

## Additional Resources

- [CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)
- [AWS WAF Developer Guide](https://docs.aws.amazon.com/waf/latest/developerguide/)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [Prebid Server Documentation](https://docs.prebid.org/prebid-server/overview/prebid-server-overview.html)

---

## Support

For issues or questions:
1. Review this guide and the module README
2. Check AWS CloudFront documentation
3. Review CloudWatch logs and metrics
4. Open an issue in this repository
