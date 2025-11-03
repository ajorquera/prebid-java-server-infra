variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "prebid-server"
}

variable "image_name" {
  description = "Container image name in Artifact Registry"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}
variable "repository_id" {
  description = "Container repository ID"
  type        = string
}

variable ssl_certificate_arn {
  description = "ARN of the SSL certificate"
  type        = string
}

variable domain_names {
  description = "List of domain names for the Prebid Server"
  type        = list(string)
}

variable desired_count {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}