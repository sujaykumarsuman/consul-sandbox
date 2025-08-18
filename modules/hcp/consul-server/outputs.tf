output "hcp_consul_cluster_url" {
  value = hcp_consul_cluster.main.consul_public_endpoint_url
}

output "hcp_consul_cluster_id" {
  value = hcp_consul_cluster.main.cluster_id
}

output "consul_config_file" {
  value = hcp_consul_cluster.main.consul_config_file
}

output "consul_ca_file" {
  value = hcp_consul_cluster.main.consul_ca_file
}

output "hcp_admin_token" {
  value     = hcp_consul_cluster_root_token.admin.secret_id
  sensitive = true
}

output "datacenter" {
  value = hcp_consul_cluster.main.datacenter
}
