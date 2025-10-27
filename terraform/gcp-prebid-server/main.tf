terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
      docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

locals {
  DOCKER_REGISTRY_URL = "${var.gcp_region}-docker.pkg.dev"
}

provider docker {
  host = "unix:///Users/andres/.docker/run/docker.sock"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "google_project_service" "gcp_services" {
  for_each = toset([
    "run.googleapis.com",
    "containerregistry.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
  ])
  project = var.gcp_project_id
  service = each.key
}

# Service Account for Cloud Run
resource "google_service_account" "cloudrun_sa" {
  account_id   = "${var.project_name}-cloudrun-sa"
  display_name = "Cloud Run Service Account for ${var.project_name}"
  description  = "Service account for Prebid Server Cloud Run service"
}

resource "google_artifact_registry_repository" "default" {
  repository_id = var.repository_id
  location      = var.gcp_region
  format        = "DOCKER"
}

resource "google_storage_bucket" "default" {
  name     = "cloudrun-service"
  project  = var.gcp_project_id
  location = var.gcp_region
  uniform_bucket_level_access = true
}

resource "terraform_data" "build_deploy_image" {
  provisioner "local-exec" {
    # set multiline
    environment = {
      GCP_PROJECT_ID  = var.gcp_project_id,
      REPOSITORY_ID  = "${var.gcp_project_id}/${var.repository_id}",
      IMAGE_NAME      = var.image_name,
      REGISTRY_URL    = local.DOCKER_REGISTRY_URL
    }
    command = "${path.root}/../scripts/build-push-image.sh"
  }

  triggers_replace = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.root}/../docker", "*"): filesha1("${path.root}/../docker/${f}")]))
  }
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "prebid_server" {
  name     = var.project_name
  location = var.gcp_region
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"
  scaling {
    max_instance_count = var.max_instances
    min_instance_count = var.min_instances
  }

  template {
    volumes {
      name = "bucket"
      gcs {
        bucket    = google_storage_bucket.default.name
        read_only = false
      }
    }
    max_instance_request_concurrency = var.container_concurrency

    containers {
      
      image = "${local.DOCKER_REGISTRY_URL}/${var.gcp_project_id}/${var.repository_id}/${var.image_name}"

      ports {
        container_port = 8080
      }

      volume_mounts {
        name       = "bucket"
        mount_path = "/mnt/efs"
      }

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }
      startup_probe {
          http_get {
            path = var.health_check_path
            port = var.container_port
          }
          initial_delay_seconds = 10
          timeout_seconds       = 5
          period_seconds        = 10
          failure_threshold     = 3
        }

        liveness_probe {
          http_get {
            path = var.health_check_path
            port = var.container_port
          }
          initial_delay_seconds = 30
          timeout_seconds       = 5
          period_seconds        = 10
          failure_threshold     = 3
        }
      }
    }

  depends_on = [ google_project_service.gcp_services[0] ]
}
