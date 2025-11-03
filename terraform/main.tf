terraform {
  backend "local" {}
}

module "aws-tfstate" {
  source  = "ajorquera/modules/ajorquera//modules/aws-tfstate"
  version = "1.0.1"
  bucket_prefix = "lngtd-new"
}


provider "aws" {
  region = var.aws_region
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}


module "aws-prebid-server" {
  source              = "./aws-prebid-server"
  repository_id       = var.repository_id
  image_name          = var.image_name
  project_name        = var.project_name
  aws_region          = var.aws_region
  domain_names        = var.domain_names
  ssl_certificate_arn = var.ssl_certificate_arn
  desired_count       = var.desired_count
}

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
