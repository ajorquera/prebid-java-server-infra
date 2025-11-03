output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.default.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.default.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.default.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.prebid_logs.name
}
