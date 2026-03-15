output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "app_subnet_id" {
  value = google_compute_subnetwork.app.id
}
