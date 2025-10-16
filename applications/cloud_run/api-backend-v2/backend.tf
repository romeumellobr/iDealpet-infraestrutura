terraform {
  backend "gcs" {
    bucket = "idealpet-terraform"
    prefix = "applications/cloud_run/api-backend-v2"
  }
}
