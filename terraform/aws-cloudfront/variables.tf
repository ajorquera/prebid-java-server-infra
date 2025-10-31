variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer to use as origin"
  type        = string
}

variable "enable_waf" {
  description = "Enable AWS WAF for CloudFront distribution"
  type        = bool
  default     = false
}

variable "price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate in ACM (us-east-1 region). If not provided, CloudFront default certificate will be used"
  type        = string
  default     = ""
}

variable "domain_names" {
  description = "List of domain names for the CloudFront distribution. Only needed if using custom SSL certificate"
  type        = list(string)
  default     = []
}

variable "default_ttl" {
  description = "Default TTL for cached objects (seconds)"
  type        = number
  default     = 86400
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects (seconds)"
  type        = number
  default     = 31536000
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects (seconds)"
  type        = number
  default     = 0
}

variable "enable_compression" {
  description = "Enable automatic compression for CloudFront"
  type        = bool
  default     = true
}

variable "viewer_protocol_policy" {
  description = "Protocol policy for viewers"
  type        = string
  default     = "redirect-to-https"
  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "Viewer protocol policy must be allow-all, https-only, or redirect-to-https."
  }
}

variable "allowed_methods" {
  description = "HTTP methods that CloudFront processes and forwards to the origin"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
}

variable "cached_methods" {
  description = "HTTP methods that CloudFront caches responses for"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
