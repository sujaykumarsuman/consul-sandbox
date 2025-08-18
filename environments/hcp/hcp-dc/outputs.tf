output "datacenter" {
  value = local.hcp_clusters["hcp_dc"].cluster_id
}

output "hcp_hvn_id" {
  value = "hvn-${local.hcp_clusters["hcp_dc"].cluster_id}"
}
