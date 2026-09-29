# ============================================================
#  JOUR 7 / 10 — Terraform : Tests
#  Code testé avec : fmt · validate · tflint · checkov
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    local  = { source = "hashicorp/local", version = "~> 2.4" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "local" {}
provider "random" {}

locals {
  environnements = {
    dev     = { replicas = 1, log_level = "DEBUG", objectif = 20000 }
    staging = { replicas = 2, log_level = "INFO", objectif = 50000 }
    prod    = { replicas = 3, log_level = "WARNING", objectif = 100000 }
  }
  projet = var.nom_projet
  env    = var.environnement
}

resource "random_id" "deploy_id" {
  for_each    = local.environnements
  byte_length = 4
}

resource "local_file" "config" {
  for_each = local.environnements

  filename        = "${path.module}/output/${each.key}/config.json"
  file_permission = "0644"
  content = jsonencode({
    environnement = each.key
    projet        = local.projet
    replicas      = each.value.replicas
    log_level     = each.value.log_level
    objectif_ca   = each.value.objectif
    deploy_id     = random_id.deploy_id[each.key].hex
  })
}

resource "local_file" "env_file" {
  for_each = local.environnements

  filename        = "${path.module}/output/${each.key}/.env"
  file_permission = "0600"
  content         = <<-EOT
    PROJET=${local.projet}
    ENV=${each.key}
    REPLICAS=${each.value.replicas}
    LOG_LEVEL=${each.value.log_level}
    OBJECTIF=${each.value.objectif}
  EOT
}
