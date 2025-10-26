terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
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

# Enable required APIs
resource "google_project_service" "cloudrun" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "containerregistry" {
  service            = "containerregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Service Account for Cloud Run
resource "google_service_account" "cloudrun_sa" {
  account_id   = "${var.project_name}-cloudrun-sa"
  display_name = "Cloud Run Service Account for ${var.project_name}"
  description  = "Service account for Prebid Server Cloud Run service"
}

# Cloud Run Service
resource "google_cloud_run_service" "prebid_server" {
  name     = var.project_name
  location = var.gcp_region

  template {
    spec {
      service_account_name = google_service_account.cloudrun_sa.email
      
      containers {
        image = var.container_image

        ports {
          container_port = var.container_port
        }

        env {
          name  = "ENVIRONMENT"
          value = var.environment
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

      container_concurrency = var.container_concurrency
      timeout_seconds       = var.timeout_seconds
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = var.min_instances
        "autoscaling.knative.dev/maxScale" = var.max_instances
        "run.googleapis.com/cpu-throttling" = "false"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  depends_on = [
    google_project_service.cloudrun
  ]
}

# IAM policy to allow public access (or restrict as needed)
resource "google_cloud_run_service_iam_member" "public_access" {
  count = var.allow_public_access ? 1 : 0

  service  = google_cloud_run_service.prebid_server.name
  location = google_cloud_run_service.prebid_server.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Global External HTTP(S) Load Balancer
resource "google_compute_global_address" "default" {
  name = "${var.project_name}-lb-ip"
}

# Health check for the backend service
resource "google_compute_health_check" "default" {
  name = "${var.project_name}-health-check"

  timeout_sec        = 5
  check_interval_sec = 10
  healthy_threshold  = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.container_port
    request_path = var.health_check_path
  }

  depends_on = [google_project_service.compute]
}

# Backend service for Cloud Run
resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  name                  = "${var.project_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.gcp_region

  cloud_run {
    service = google_cloud_run_service.prebid_server.name
  }
}

resource "google_compute_backend_service" "default" {
  name = "${var.project_name}-backend"

  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = var.timeout_seconds

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg.id
  }

  log_config {
    enable = true
    sample_rate = 1.0
  }
}

# URL map
resource "google_compute_url_map" "default" {
  name            = "${var.project_name}-url-map"
  default_service = google_compute_backend_service.default.id
}

# HTTP proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.project_name}-http-proxy"
  url_map = google_compute_url_map.default.id
}

# Forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.project_name}-forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}
