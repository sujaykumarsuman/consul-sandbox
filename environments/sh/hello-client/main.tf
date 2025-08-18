provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "sh_dc" {
  backend = "local"
  config = {
    path = "../sh-dc/terraform.tfstate"
  }
}

module "hello_client" {
  source = "../../../modules/sh/consul-client-ecs"

  datacenter         = data.terraform_remote_state.sh_dc.outputs.datacenter
  payload_image      = var.payload_image
  payload_port       = 8080
  payload_id         = "hello-client-sh-dc-01"
  payload_command    = ["./hello-client", "hello-client-sh-dc-01", "hello-server.service.consul:5050"]
  consul_http_addr   = data.terraform_remote_state.sh_dc.outputs.consul_http_addr
  consul_ent_license = var.consul_ent_license
}
