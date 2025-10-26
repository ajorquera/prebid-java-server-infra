terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Route 53 Hosted Zone (if you have a domain)
resource "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

# Health check for AWS ALB
resource "aws_route53_health_check" "aws_alb" {
  count             = var.domain_name != "" ? 1 : 0
  fqdn              = var.aws_lb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${var.project_name}-aws-health-check"
  }
}

# Primary DNS record (AWS Fargate)
resource "aws_route53_record" "primary" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  type    = "A"

  alias {
    name                   = var.aws_lb_dns_name
    zone_id                = var.aws_alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "primary-aws"
  health_check_id = aws_route53_health_check.aws_alb[0].id
}

# Secondary DNS record (GCP Cloud Run)
resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  type    = "CNAME"
  ttl     = 60

  records = [var.gcp_cloudrun_url]

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary-gcp"

  depends_on = [ var.gcp_cloudrun_url ]
}
