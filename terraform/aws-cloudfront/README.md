# AWS CloudFront Distribution Module

This module creates an AWS CloudFront distribution that sits in front of the Application Load Balancer (ALB) to provide:

- **Global Content Delivery**: Edge locations worldwide for lower latency
- **DDoS Protection**: Built-in AWS Shield Standard
- **SSL/TLS Termination**: HTTPS support with custom domains
- **Caching**: Configurable caching for improved performance
- **Security**: Optional AWS WAF integration for additional protection
- **Compression**: Automatic Gzip and Brotli compression

## Architecture

```
User → CloudFront (Edge Locations) → ALB → ECS Fargate Tasks
```

## Features

### Caching Configuration
- Optimized for Prebid Server's dynamic content nature
- Minimal default caching (0 seconds)
- Forwards all query parameters, cookies, and headers
- Respects cache-control headers from origin

### Security Features
- HTTPS redirect by default
- Security headers (HSTS, X-Frame-Options, etc.)
- Optional AWS WAF with managed rule sets
- Rate limiting (2000 requests per 5 minutes per IP when WAF enabled)
- Origin access control

### Logging
- Access logs stored in S3 bucket
- CloudWatch Logs integration
- Configurable log retention

## Usage

### Basic Usage (No Custom Domain)

```hcl
module "aws-cloudfront" {
  source = "./aws-cloudfront"

  project_name = "prebid-server"
  alb_dns_name = module.aws-prebid-server.alb_dns_name
}
```

### With Custom Domain

```hcl
module "aws-cloudfront" {
  source = "./aws-cloudfront"

  project_name        = "prebid-server"
  alb_dns_name        = module.aws-prebid-server.alb_dns_name
  
  # Custom domain configuration
  ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
  domain_names        = ["prebid.example.com"]
}
```

**Note**: SSL certificates for CloudFront must be in the `us-east-1` region, even if your ALB is in a different region.

### With WAF Protection

```hcl
module "aws-cloudfront" {
  source = "./aws-cloudfront"

  project_name = "prebid-server"
  alb_dns_name = module.aws-prebid-server.alb_dns_name
  enable_waf   = true
  
  # Optional: Customize other settings
  price_class = "PriceClass_All"  # Use all edge locations
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | - | yes |
| alb_dns_name | DNS name of the ALB to use as origin | string | - | yes |
| enable_waf | Enable AWS WAF for CloudFront | bool | false | no |
| price_class | CloudFront distribution price class | string | "PriceClass_100" | no |
| ssl_certificate_arn | ARN of SSL certificate in ACM (us-east-1) | string | "" | no |
| domain_names | List of domain names for CloudFront | list(string) | [] | no |
| default_ttl | Default TTL for cached objects (seconds) | number | 0 | no |
| max_ttl | Maximum TTL for cached objects (seconds) | number | 86400 | no |
| min_ttl | Minimum TTL for cached objects (seconds) | number | 0 | no |
| enable_compression | Enable automatic compression | bool | true | no |
| viewer_protocol_policy | Protocol policy for viewers | string | "redirect-to-https" | no |
| log_retention_days | CloudWatch log retention in days | number | 7 | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudfront_distribution_id | ID of the CloudFront distribution |
| cloudfront_domain_name | Domain name of the CloudFront distribution |
| cloudfront_arn | ARN of the CloudFront distribution |
| cloudfront_hosted_zone_id | CloudFront Route 53 zone ID |
| cloudfront_status | Current status of the distribution |
| waf_web_acl_id | ID of the WAF Web ACL (if enabled) |
| waf_web_acl_arn | ARN of the WAF Web ACL (if enabled) |
| cloudfront_logs_bucket | S3 bucket for CloudFront logs |

## Price Classes

CloudFront offers three price classes:

- **PriceClass_100**: US, Canada, and Europe (most cost-effective)
- **PriceClass_200**: All locations except South America, Australia, and New Zealand
- **PriceClass_All**: All edge locations worldwide

## Caching Strategy

This module is configured for Prebid Server's dynamic content:

1. **Default Caching**: Disabled (TTL = 0)
2. **Respects Origin Headers**: Forwards all cache-control headers
3. **Query Strings**: All query strings are forwarded and included in cache key
4. **Cookies**: All cookies are forwarded
5. **Headers**: Important headers (Host, User-Agent, etc.) are forwarded

This ensures that dynamic bid requests are not cached while allowing the origin to control caching for static assets if needed.

## WAF Protection

When enabled, the WAF includes:

1. **AWS Managed Rules - Common Rule Set**: Protection against common threats
2. **AWS Managed Rules - Known Bad Inputs**: Protection against known malicious inputs
3. **Rate Limiting**: 2000 requests per 5 minutes per IP address

## Custom Domain Setup

To use a custom domain with CloudFront:

1. **Create SSL Certificate in ACM**:
   ```bash
   # Must be in us-east-1 region for CloudFront
   aws acm request-certificate \
     --domain-name prebid.example.com \
     --validation-method DNS \
     --region us-east-1
   ```

2. **Validate the Certificate**:
   - Add the DNS validation records to your domain

3. **Configure Module**:
   ```hcl
   ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
   domain_names        = ["prebid.example.com"]
   ```

4. **Update DNS**:
   - Create a CNAME record pointing your domain to the CloudFront domain name
   - Or use Route 53 alias record pointing to CloudFront

## Deployment

1. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

2. **Plan Changes**:
   ```bash
   terraform plan
   ```

3. **Apply Configuration**:
   ```bash
   terraform apply
   ```

4. **Get CloudFront URL**:
   ```bash
   terraform output cloudfront_domain_name
   ```

## Testing

After deployment, test the CloudFront distribution:

```bash
# Get the CloudFront domain name
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)

# Test health endpoint
curl https://${CLOUDFRONT_DOMAIN}/status

# Check CloudFront headers
curl -I https://${CLOUDFRONT_DOMAIN}/status
```

You should see CloudFront-specific headers like:
- `X-Cache: Miss from cloudfront` (first request)
- `X-Amz-Cf-Id: ...`
- `Via: ... CloudFront`

## Monitoring

### CloudWatch Metrics

CloudFront automatically publishes metrics to CloudWatch:
- Requests
- Bytes Downloaded/Uploaded
- 4xx/5xx Error Rates
- Cache Hit Rate

### Access Logs

Access logs are stored in the S3 bucket and automatically expire after the configured retention period.

### WAF Metrics (if enabled)

When WAF is enabled, additional metrics are available:
- AllowedRequests
- BlockedRequests
- CountedRequests

## Cost Considerations

### CloudFront Costs
- **Data Transfer Out**: $0.085 - $0.250 per GB (varies by region)
- **HTTP/HTTPS Requests**: $0.0075 - $0.0220 per 10,000 requests
- **No minimum fee**: Pay only for what you use

### WAF Costs (if enabled)
- **Web ACL**: $5.00 per month
- **Rules**: $1.00 per rule per month (3 rules = $3.00/month)
- **Requests**: $0.60 per million requests

### Example Monthly Cost
Without WAF: ~$50-100/month (depends on traffic)
With WAF: ~$60-110/month

## Troubleshooting

### Issue: 502 Bad Gateway from CloudFront

**Solution**: Check that:
1. ALB is healthy and responding
2. Security groups allow CloudFront to access ALB
3. Origin protocol is correctly configured

### Issue: High Cache Miss Rate

**Solution**: This is expected for Prebid Server's dynamic content. The cache is intentionally configured with minimal caching.

### Issue: Custom Domain Not Working

**Solution**: Verify:
1. SSL certificate is in us-east-1 region
2. Certificate is validated and issued
3. DNS records point to CloudFront domain
4. Domain names are added to CloudFront configuration

## Security Best Practices

1. **Enable WAF**: For production environments, enable WAF for additional protection
2. **Use HTTPS Only**: Always use `redirect-to-https` policy
3. **Monitor Logs**: Regularly review CloudFront and WAF logs
4. **Rotate Certificates**: Keep SSL certificates up to date
5. **Restrict Origins**: Consider adding custom headers for origin authentication

## Integration with Failover

When using CloudFront with the failover module, you have two options:

### Option 1: CloudFront Only for AWS
Route 53 → CloudFront (AWS) → ALB (Primary)
              ↓ (failover)
         Cloud Run (GCP, Secondary)

### Option 2: No CloudFront for Failover
Route 53 → ALB (AWS, Primary)
         ↓ (failover)
         Cloud Run (GCP, Secondary)

Choose based on your requirements for caching and edge delivery.

## References

- [CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)
- [AWS WAF Developer Guide](https://docs.aws.amazon.com/waf/latest/developerguide/)
- [Prebid Server Documentation](https://docs.prebid.org/prebid-server/overview/prebid-server-overview.html)
