data "terraform_remote_state" "load_balancer" {
  backend = "gcs"
  config = {
    bucket = "idealpet-terraform"
    prefix = "core/load_balancer/${var.gcp_project_environment}/lb_${var.gcp_project_environment}"
  }
}

resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "neg-${var.cloud_run_service_name}-${var.gcp_project_environment}"
  region                = var.gcp_project_region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = "${var.cloud_run_service_name}-${var.gcp_project_environment}"
  }
}

resource "google_compute_backend_service" "backend_service" {
  name                  = "backend-${var.cloud_run_service_name}-${var.gcp_project_environment}"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTPS"                     
  security_policy       = "${var.security_policy}-${var.gcp_project_environment}"

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg.id
  }
}

data "google_dns_managed_zone" "idealpet" {
  name = var.domain  # Ex.: "ideepet"
}

data "google_compute_global_address" "shared_lb_ip" {
  name    = "shared-lb-ip-${var.gcp_project_environment}" 
  project = "${var.gcp_project_id}"  
}

resource "google_dns_record_set" "a_record" {
  name = var.gcp_project_environment == "production" ? "${var.sub_domain_service}.ideepet.com.br." : "${var.sub_domain_service}.${var.gcp_project_environment}.ideepet.com.br."

  managed_zone = data.google_dns_managed_zone.idealpet.name
  type         = "A"
  ttl          = 300

  rrdatas = [data.google_compute_global_address.shared_lb_ip.address]
}

# Exportar informações necessárias para atualizar o url_map
output "backend_service_id" {
  value = google_compute_backend_service.backend_service.id
}

output "host" {
  value = var.gcp_project_environment == "production" ? "${var.sub_domain_service}.ideepet.com.br" : "${var.sub_domain_service}.${var.gcp_project_environment}.ideepet.com.br"
}

output "path_matcher_name" {
  value = "${var.cloud_run_service_name}-${var.gcp_project_environment}-path-matcher"
}

output "gcp_project_environment" {
  value = var.gcp_project_environment
}