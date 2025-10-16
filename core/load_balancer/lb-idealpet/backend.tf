terraform {
  backend "gcs" {
    bucket = "idealpet-terraform"
    prefix = "core/load_balancer"
  }
}
