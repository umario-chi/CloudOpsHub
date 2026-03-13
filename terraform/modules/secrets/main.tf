resource "google_secret_manager_secret" "database_url" {
  secret_id = "${var.project_name}-database-url-${var.environment}"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.database_url.id
  secret_data = "mysql://${var.db_user}:${var.db_password}@${var.db_private_ip}:3306/${var.db_name}"
}

resource "google_secret_manager_secret" "ecr_credentials" {
  secret_id = "${var.project_name}-ecr-creds-${var.environment}"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ecr_credentials" {
  secret      = google_secret_manager_secret.ecr_credentials.id
  secret_data = jsonencode({
    aws_account_id = var.aws_account_id
    aws_region     = var.aws_region
    registry       = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  })
}
