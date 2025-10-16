terraform {
  required_version = ">= 1.4.0"
  required_providers {
    google = {
        source = "hashicorp/google"
        version = ">= 6.23.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
}