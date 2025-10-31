output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.prebid_distribution.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.prebid_distribution.domain_name
}

output "cloudfront_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.prebid_distribution.arn
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront Route 53 zone ID"
  value       = aws_cloudfront_distribution.prebid_distribution.hosted_zone_id
}

output "cloudfront_status" {
  description = "Current status of the CloudFront distribution"
  value       = aws_cloudfront_distribution.prebid_distribution.status
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL (if enabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.cloudfront_waf[0].id : null
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL (if enabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.cloudfront_waf[0].arn : null
}

output "cloudfront_logs_bucket" {
  description = "S3 bucket for CloudFront logs"
  value       = aws_s3_bucket.cloudfront_logs.id
}
