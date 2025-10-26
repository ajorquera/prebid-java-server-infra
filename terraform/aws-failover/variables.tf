variable "project_name" {
  description = "Project name"
  type        = string
  default     = "prebid-server"
}

variable "domain_name" {
  description = "Domain name for Route 53 (leave empty to skip DNS setup)"
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain for the service (e.g., 'api' for api.example.com)"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/status"
}

variable "gcp_cloudrun_url" {
  description = "GCP Cloud Run URL (without https://)"
  type        = string
  default     = ""
}

variable "aws_lb_dns_name" {
  description = "AWS Load Balancer DNS name"
  type        = string
}

variable "aws_alb_zone_id" {
  description = "AWS Load Balancer Zone ID"
  type        = string
}
