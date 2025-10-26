output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = var.domain_name != "" ? aws_route53_zone.main[0].zone_id : ""
}

output "route53_nameservers" {
  description = "Route 53 nameservers"
  value       = var.domain_name != "" ? aws_route53_zone.main[0].name_servers : []
}

output "primary_record_fqdn" {
  description = "FQDN of the primary record"
  value       = var.domain_name != "" ? aws_route53_record.primary[0].fqdn : ""
}

output "health_check_id" {
  description = "Health check ID"
  value       = var.domain_name != "" ? aws_route53_health_check.aws_alb[0].id : ""
}
