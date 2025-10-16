# Importa o certificado SSL existente
data "google_compute_ssl_certificate" "existing_ssl_cert" {
  name = var.ssl_certificate_name
}

# Cria um novo certificado SSL managed apenas para ideepet.com.br
resource "google_compute_managed_ssl_certificate" "idealpet_ssl_cert_v8" {
  name = "idealpet-certificate-ssl-v8"

  managed {
    domains = [
      "api.ideepet.com.br",
      "biometria.ideepet.com.br",
      "blockchain.ideepet.com.br", 
      "ideepet.com.br"
    ]
  }
}

# Define o Backend Service padrão
resource "google_compute_backend_service" "default_backend" {
  name                  = "default-backend-service-${var.gcp_project_environment}"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTPS"
}

# Configura o URL Map compartilhado
resource "google_compute_url_map" "shared_url_map" {
  name            = "${var.loading_balancer}-${var.gcp_project_environment}"
  default_service = google_compute_backend_service.default_backend.id
}

# Configura o HTTPS Proxy compartilhado
resource "google_compute_target_https_proxy" "shared_https_proxy" {
  name            = "shared-https-proxy-${var.gcp_project_environment}"
  url_map         = google_compute_url_map.shared_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.idealpet_ssl_cert_v8.self_link]
}

# Reserva um endereço IP global para o Load Balancer
resource "google_compute_global_address" "shared_lb_ip" {
  name = "shared-lb-ip-${var.gcp_project_environment}"
}

# Configura a regra de encaminhamento global
resource "google_compute_global_forwarding_rule" "shared_forwarding_rule" {
  name                  = "shared-lb-ip-${var.gcp_project_environment}-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.shared_https_proxy.id
  ip_address            = google_compute_global_address.shared_lb_ip.address
}

# Outputs para serem referenciados por outros módulos
output "shared_url_map_id" {
  value = google_compute_url_map.shared_url_map.id
}

output "shared_https_proxy_id" {
  value = google_compute_target_https_proxy.shared_https_proxy.id
}

output "default_backend_service_id" {
  value = google_compute_backend_service.default_backend.id
}
