output "ssh_private_key_path" {
  description = "Absolute path to the SSH private key for the Consul server"
  value       = local.ssh_key_path
}

output "server_public_ip" {
  description = "Public IP address of the Consul server"
  value       = var.server_public_ip
}
