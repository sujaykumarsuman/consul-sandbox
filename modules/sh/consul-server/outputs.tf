output "datacenter" {
  value = var.datacenter
}

output "consul_http_addr" {
  value = "http://${aws_instance.server.public_ip}:8500"
}

output "public_ip" {
  value = aws_instance.server.public_ip
}

output "ssh_private_key_path" {
  value = local_file.ssh_key_pem.filename
}
