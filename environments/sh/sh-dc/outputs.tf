output "datacenter" {
  value = module.consul_server.datacenter
}

output "consul_http_addr" {
  value = module.consul_server.consul_http_addr
}
