# Terraform Configuration Examples

This directory contains example Terraform configurations for common deployment scenarios.

## Available Examples

### 1. Basic CloudFront Setup
**File**: `cloudfront-basic.tf.example`

The simplest CloudFront configuration with default settings:
- Uses CloudFront default SSL certificate
- Standard caching behavior (optimized for Prebid Server)
- US, Canada, and Europe edge locations (PriceClass_100)
- No WAF (can be added later)

**Use Case**: Quick testing and development environments

**Monthly Cost**: ~$50-100 (depending on traffic)

---

### 2. CloudFront with WAF
**File**: `cloudfront-with-waf.tf.example`

Production-ready CloudFront with security enhancements:
- AWS WAF enabled with managed rules
- Rate limiting (2000 req/5min per IP)
- DDoS protection
- More edge locations (PriceClass_200)
- Compression enabled

**Use Case**: Production environments requiring enhanced security

**Monthly Cost**: ~$65-120 (including WAF)

---

### 3. CloudFront with Custom Domain
**File**: `cloudfront-custom-domain.tf.example`

CloudFront configured with your own domain name:
- Custom SSL certificate from ACM
- Custom domain names (e.g., prebid.example.com)
- Route 53 alias record configuration
- HTTPS enforcement
- Optional WAF integration

**Use Case**: Production deployments with branded URLs

**Monthly Cost**: ~$50-120 (depending on traffic and WAF)

**Prerequisites**:
- Domain name
- ACM certificate in us-east-1 region
- Route 53 hosted zone (or external DNS)

---

## How to Use These Examples

### Step 1: Choose an Example

Select the example that best fits your needs:
- Starting out? Use **cloudfront-basic.tf.example**
- Need security? Use **cloudfront-with-waf.tf.example**
- Have a domain? Use **cloudfront-custom-domain.tf.example**

### Step 2: Copy Configuration

Copy the example configuration to your `main.tf`:

```bash
# From the terraform directory
cat examples/cloudfront-basic.tf.example >> main.tf
```

Or manually copy the relevant sections.

### Step 3: Customize Variables

Update the configuration with your specific values:
- Replace `project_name` with your project name
- Update domain names and certificate ARNs if using custom domain
- Adjust `price_class` based on your geographic needs
- Set `enable_waf` based on your security requirements

### Step 4: Apply Configuration

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 5: Test

```bash
# Get CloudFront URL
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)

# Test the endpoint
curl https://${CLOUDFRONT_URL}/status
```

---

## Configuration Comparison

| Feature | Basic | With WAF | Custom Domain |
|---------|-------|----------|---------------|
| Cost | $ | $$ | $-$$ |
| Setup Time | 10 min | 15 min | 30 min |
| Security | Basic | Enhanced | Enhanced |
| Custom Domain | ❌ | ❌ | ✅ |
| DDoS Protection | Standard | Enhanced | Enhanced |
| Rate Limiting | ❌ | ✅ | Optional |
| Edge Locations | 100 (US/EU/CA) | 200 (Most) | 100-All |

---

## Next Steps

After deploying CloudFront:

1. **Monitor Performance**: Check CloudWatch metrics
2. **Review Costs**: Monitor AWS Cost Explorer
3. **Optimize Caching**: Adjust TTL values based on your needs
4. **Add Custom Rules**: Configure additional WAF rules if needed
5. **Set Up Alerts**: Create CloudWatch alarms for key metrics

---

## Troubleshooting

### Issue: Configuration Doesn't Work

**Solution**: Make sure you:
1. Have deployed the AWS Prebid Server first (`module.aws-prebid-server`)
2. Uncommented the CloudFront module in main.tf
3. Run `terraform init` to download providers
4. Check for Terraform validation errors: `terraform validate`

### Issue: Custom Domain Not Resolving

**Solution**: Verify:
1. ACM certificate is in us-east-1 region
2. Certificate is validated and issued (Status: "Issued")
3. DNS records are correctly configured
4. Wait for DNS propagation (up to 48 hours)

### Issue: High Costs

**Solution**:
1. Review CloudWatch metrics to understand traffic patterns
2. Consider using PriceClass_100 instead of PriceClass_All
3. Disable WAF if not needed
4. Optimize caching to reduce origin requests

---

## Additional Resources

- [CloudFront Setup Guide](../../docs/CLOUDFRONT_SETUP.md)
- [Module README](../aws-cloudfront/README.md)
- [Main README](../../README.md)
- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)

---

## Contributing

Have a useful example? Feel free to contribute:
1. Create a new `.tf.example` file
2. Add clear comments explaining the configuration
3. Update this README with details about your example
4. Submit a pull request
