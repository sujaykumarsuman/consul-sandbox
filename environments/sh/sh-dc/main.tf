terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  client_config_dir = "${path.module}/../../../shared/config/client_config/${var.datacenter}"
  server_config_dir = "${path.module}/../../../shared/config/server_config/${var.datacenter}"
}

# Create directories for config bundles
resource "null_resource" "create_config_dirs" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.client_config_dir} ${local.server_config_dir}"
  }
}

resource "random_id" "gossip_key" {
  byte_length = 16
}

resource "random_uuid" "admin_token" {}

resource "local_file" "server_config" {
  depends_on = [null_resource.create_config_dirs]
  filename   = "${local.server_config_dir}/server_config.json"
  content = jsonencode({
    datacenter              = var.datacenter
    log_level               = "INFO"
    server                  = true
    ui                      = true
    client_addr             = "0.0.0.0"
    bind_addr               = "0.0.0.0"
    bootstrap_expect        = 1
    encrypt                 = random_id.gossip_key.b64_std
    encrypt_verify_incoming = true
    encrypt_verify_outgoing = true
    retry_join              = []
    acl = {
      enabled        = false
      down_policy    = ""
      default_policy = ""
    }
    auto_encrypt = { tls = false }
    tls          = { defaults = { verify_outgoing = false } }
    connect      = { enabled = false }
  })
}

resource "local_file" "server_ca" {
  depends_on = [null_resource.create_config_dirs]
  filename   = "${local.server_config_dir}/ca.pem"
  content    = ""
}

resource "local_file" "server_admin_token" {
  depends_on = [null_resource.create_config_dirs]
  filename   = "${local.server_config_dir}/admin_token.txt"
  content    = random_uuid.admin_token.result
}

module "consul_server" {
  source = "../../../modules/sh/consul-server"

  datacenter         = var.datacenter
  instance_type      = var.instance_type
  consul_ent_license = var.consul_ent_license

  depends_on = [local_file.server_config, local_file.server_ca, local_file.server_admin_token]
}

# Client configuration
resource "local_file" "client_config" {
  depends_on = [module.consul_server, null_resource.create_config_dirs]
  filename   = "${local.client_config_dir}/client_config.json"
  content = jsonencode({
    datacenter              = var.datacenter
    log_level               = "INFO"
    server                  = false
    ui                      = false
    client_addr             = "0.0.0.0"
    bind_addr               = "0.0.0.0"
    encrypt                 = random_id.gossip_key.b64_std
    encrypt_verify_incoming = true
    encrypt_verify_outgoing = true
    retry_join              = [module.consul_server.private_ip]
    acl = {
      enabled        = false
      down_policy    = ""
      default_policy = ""
    }
    auto_encrypt = { tls = false }
    tls          = { defaults = { verify_outgoing = false } }
    connect      = { enabled = true }
  })
}

resource "local_file" "client_ca" {
  depends_on = [null_resource.create_config_dirs]
  filename   = "${local.client_config_dir}/ca.pem"
  content    = ""
}

resource "local_file" "client_admin_token" {
  depends_on = [null_resource.create_config_dirs]
  filename   = "${local.client_config_dir}/admin_token.txt"
  content    = random_uuid.admin_token.result
}

