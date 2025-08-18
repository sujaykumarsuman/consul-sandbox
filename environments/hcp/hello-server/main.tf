provider "aws" {
  region = var.aws_region
}

provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
}

data "terraform_remote_state" "hcp_dc" {
  backend = "local"
  config = {
    path = "../hcp-dc/terraform.tfstate"
  }
}

module "payload_consul_server" {
  source = "../../../modules/hcp/consul-client"

  providers = {
    aws = aws
    hcp = hcp
  }

  consul_ent_license = var.consul_ent_license
  hcp_project_id     = var.hcp_project_id
  hcp_hvn_id         = data.terraform_remote_state.hcp_dc.outputs.hcp_hvn_id
  hcp_client_id      = var.hcp_client_id
  hcp_client_secret  = var.hcp_client_secret
  hcp_cidr_block     = var.hcp_cidr_block
  payload_binary     = "hello-server"
  payload_port       = 0
  payload_id         = "hello-server-hcp-dc-01"
  datacenter         = data.terraform_remote_state.hcp_dc.outputs.datacenter
}

# create a local file to store the private key in PEM format
# This file will be used to SSH into the Consul client instance
resource "local_file" "private_key_pem" {
  content              = module.payload_consul_server.ssh_private_key
  filename             = "${path.module}/client-key.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}
