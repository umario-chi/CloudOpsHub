output "database_url_secret_id" {
  value = google_secret_manager_secret.database_url.secret_id
}

output "ecr_credentials_secret_id" {
  value = google_secret_manager_secret.ecr_credentials.secret_id
}
