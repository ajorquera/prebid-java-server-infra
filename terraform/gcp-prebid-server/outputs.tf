output "cloudrun_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.prebid_server.uri
}

output "cloudrun_service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.prebid_server.name
}

