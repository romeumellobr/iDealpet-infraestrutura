variable "gcp_project_alias" {
    type = string
    description = "alias do projeto"
}

variable "gcp_project_environment" {
    type = string
    description = "environment do projeto"
}

variable "gcp_project_id" {
    type = string
    description = "Id do Projeto GCP"
}

variable "gcp_project_number" {
    type = string
    description = "Número do projeto da GCP"
}

variable "gcp_project_name" {
    type = string
    description = "Nome do projeto da GCP"
}

variable "gcp_project_region" {
    type = string
    description = "Região default para configuração do projeto"
}

variable "gcp_project_vpc" {
    type = string
    description = "VPC"
}

variable "gcp_project_connectors" {
    type = string
    description = "Connector"
}

variable "cloud_run_service_name" {
    type = string
    description = "nome do serviço"
}

variable "tag_image" {
    type = string
    description = "tag da imagem"
}

variable "limit_cpu" {
    type = string
    description = "Quantidade de CPU"
}

variable "limit_memory" {
    type = string
    description = "Quantidade de memória"
}


variable "loading_balancer" {
    type = string
    description = "balanceador de carga"
}

variable "ssl_certificate_name" {
    type = string
    description = "ssl"
}


variable "domain" {
    type = string
    description = "dominio da idealpet"
}


variable "sub_domain_service" {
    type = string
    description = "dominio da idealpet"
}

variable "min_instances" {
  description = "Número mínimo de instâncias no Cloud Run"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Número máximo de instâncias no Cloud Run"
  type        = number
  default     = 10
}

variable "security_policy" {
    type = string
    description = "security policy"
}

variable "secret_manager_variables" {
    type = string
    description = "secret manager variables to be used in the cloud run"
}