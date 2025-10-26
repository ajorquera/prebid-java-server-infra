output "cloudrun_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_service.prebid_server.status[0].url
}

output "cloudrun_service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_service.prebid_server.name
}

output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = google_compute_global_address.default.address
}

output "service_account_email" {
  description = "Email of the service account"
  value       = google_service_account.cloudrun_sa.email
}
