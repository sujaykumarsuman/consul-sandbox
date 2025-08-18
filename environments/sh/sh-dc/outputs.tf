output "datacenter" {
  value = module.consul_server.datacenter
}

output "consul_http_addr" {
  value = module.consul_server.consul_http_addr
}

output "server_public_ip" {
  value = module.consul_server.public_ip
}

output "ssh_private_key_path" {
  value = module.consul_server.ssh_private_key_path
}
