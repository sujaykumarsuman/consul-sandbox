output "instance_public_ip" {
  value = aws_instance.consul_client_hcp.public_ip
}

output "instance_id" {
  value = aws_instance.consul_client_hcp.id
}

output "ssh_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
