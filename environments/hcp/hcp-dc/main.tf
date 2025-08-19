## This Terraform configuration sets up a HashiCorp Cloud Platform (HCP) Consul datacenter.

provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
}

# List of clusters to create in HCP Consul 
locals {
  hcp_clusters = {
    hcp_dc = {
      cluster_id     = "hcp-dc"
      cloud_provider = var.cloud_provider
      region         = var.region
      tier           = var.tier
      size           = var.size
    }
  }
}

# This Terraform configuration sets up HCP Consul clusters in a specified region and tier.
module "hcp_consul" {
  for_each = local.hcp_clusters
  source   = "../../../modules/hcp/consul-server"

  providers = {
    hcp = hcp
  }

  hcp_project_id    = var.hcp_project_id
  hcp_client_id     = var.hcp_client_id
  hcp_client_secret = var.hcp_client_secret
  cloud_provider    = each.value.cloud_provider
  region            = each.value.region
  cluster_id        = each.value.cluster_id
  tier              = each.value.tier
  size              = each.value.size
}

# Create client configuration directory and files
resource "null_resource" "create_client_config_dir" {
  for_each = module.hcp_consul

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/../../../shared/config/client_config/${each.value.datacenter} ${path.module}/../../../shared/config/server_config/${each.value.datacenter}"
  }
}

resource "local_file" "client_config_json" {
  depends_on = [module.hcp_consul, null_resource.create_client_config_dir]
  for_each   = module.hcp_consul
  # Decode the base64 encoded consul_config_file from the module output
  content  = base64decode(each.value.consul_config_file)
  filename = "${path.module}/../../../shared/config/client_config/${each.value.datacenter}/client_config.json"
}

resource "local_file" "client_ca_pem" {
  depends_on = [module.hcp_consul, null_resource.create_client_config_dir]
  for_each   = module.hcp_consul
  # Decode the base64 encoded consul_ca_file from the module output
  content  = base64decode(each.value.consul_ca_file)
  filename = "${path.module}/../../../shared/config/client_config/${each.value.datacenter}/ca.pem"
}

resource "local_file" "admin_token" {
  depends_on = [module.hcp_consul, null_resource.create_client_config_dir]
  for_each   = module.hcp_consul

  content  = each.value.hcp_admin_token
  filename = "${path.module}/../../../shared/config/client_config/${each.value.datacenter}/admin_token.txt"
}

# Server configuration bundle
resource "local_file" "server_config_json" {
  depends_on = [module.hcp_consul, null_resource.create_client_config_dir]
  for_each   = module.hcp_consul
  content = jsonencode(
    merge(
      jsondecode(base64decode(each.value.consul_config_file)),
      {
        server           = true,
        ui               = true,
        bootstrap_expect = 1,
        client_addr      = "0.0.0.0",
        bind_addr        = "0.0.0.0"
      }
    )
  )
  filename = "${path.module}/../../../shared/config/server_config/${each.value.datacenter}/server_config.json"
}

resource "local_file" "server_ca_pem" {
  depends_on = [module.hcp_consul, null_resource.create_client_config_dir]
  for_each   = module.hcp_consul
  content    = base64decode(each.value.consul_ca_file)
  filename   = "${path.module}/../../../shared/config/server_config/${each.value.datacenter}/ca.pem"
}

resource "local_file" "server_admin_token" {
  depends_on = [module.hcp_consul, null_resource.create_client_config_dir]
  for_each   = module.hcp_consul
  content    = each.value.hcp_admin_token
  filename   = "${path.module}/../../../shared/config/server_config/${each.value.datacenter}/admin_token.txt"
}
