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

data "hcp_consul_cluster" "dc" {
  project_id = var.hcp_project_id
  cluster_id = data.terraform_remote_state.hcp_dc.outputs.datacenter
}

locals {
  admin_token = trimspace(file("${path.module}/../../../shared/config/client_config/${data.terraform_remote_state.hcp_dc.outputs.datacenter}/admin_token.txt"))
}

module "hello_client" {
  source = "../../../modules/hcp/consul-client-ecs"

  providers = {
    aws = aws
    hcp = hcp
  }

  hcp_project_id    = var.hcp_project_id
  hcp_hvn_id        = data.terraform_remote_state.hcp_dc.outputs.hcp_hvn_id
  hcp_cidr_block    = var.hcp_cidr_block
  datacenter        = data.terraform_remote_state.hcp_dc.outputs.datacenter
  payload_image     = var.payload_image
  payload_port      = 8080
  payload_id        = "hello-client-hcp-dc-01"
  payload_command   = ["./hello-client", "hello-client-hcp-dc-01", "hello-server.service.consul:5050"]
  consul_http_addr  = data.hcp_consul_cluster.dc.consul_public_endpoint_url
  consul_http_token = local.admin_token
}
