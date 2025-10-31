terraform {
  backend "s3" {
    bucket = "lngtd-new-terraform-states"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

module "aws-tfstate" {
  source  = "ajorquera/modules/ajorquera//modules/aws-tfstate"
  version = "1.0.1"
  bucket_prefix = "lngtd-new"
}

locals {
  project_name      = "prebid-server"

  gcp_project_id    = "testing-account-476319"
  gcp_region        = "us-central1"
  aws_region        = "us-east-1"

  domain_name       = "createapp.click"
  subdomain         = "s2s"

  repository_id     = "prebid-server-repository"
  image_name        = "pbs"
}

provider "aws" {
  region = local.aws_region
}

provider "google" {
  project = local.gcp_project_id
  region  = local.gcp_region
}


module "aws-prebid-server" {
  source          = "./aws-prebid-server"
  repository_id   = local.repository_id
  image_name      = local.image_name
  project_name    = local.project_name
  aws_region      = local.aws_region
  desired_count   = 0
}

# CloudFront Distribution (CDN for AWS Prebid Server)
# Uncomment to enable CloudFront distribution in front of the ALB
# module "aws-cloudfront" {
#   source = "./aws-cloudfront"
#
#   project_name    = local.project_name
#   alb_dns_name    = module.aws-prebid-server.alb_dns_name
#   enable_waf      = false  # Set to true to enable AWS WAF
#   price_class     = "PriceClass_100"  # Use US, Canada, and Europe
#
#   # Optional: Custom domain configuration
#   # ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
#   # domain_names        = ["${local.subdomain}.${local.domain_name}"]
#
#   depends_on = [module.aws-prebid-server]
# }

# module "gcp-prebid-server" {
#   source = "./gcp-prebid-server"
#   gcp_project_id    = local.gcp_project_id
#   gcp_region        = local.gcp_region
#   project_name      = local.project_name
#   image_name        = local.image_name
#   min_instances     = 0
#   repository_id     = local.repository_id
# }

# module "aws-failover" {
#   source = "./aws-failover"

#   project_name      = local.project_name
#   domain_name       = local.domain_name
#   subdomain         = local.subdomain
#   gcp_cloudrun_url  = module.gcp-prebid-server.cloudrun_url
#   aws_lb_dns_name   = module.aws-prebid-server.alb_dns_name
#   aws_alb_zone_id   = module.aws-prebid-server.alb_zone_id

#   depends_on = [ module.gcp-prebid-server.cloudrun_url, module.aws-prebid-server.alb_dns_name ]
# }
