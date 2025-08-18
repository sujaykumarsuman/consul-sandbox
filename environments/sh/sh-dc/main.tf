provider "aws" {
  region = var.aws_region
}

module "consul_server" {
  source = "../../../modules/sh/consul-server"

  datacenter         = var.datacenter
  instance_type      = var.instance_type
  consul_ent_license = var.consul_ent_license
}
