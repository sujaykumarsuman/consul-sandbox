output "datacenter" {
  value = var.datacenter
}

output "consul_http_addr" {
  value = "http://${aws_instance.server.public_ip}:8500"
}
