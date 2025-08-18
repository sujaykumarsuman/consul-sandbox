output "ssh_command" {
  value = "ssh -i environments/hello-server/client-key.pem ubuntu@${module.payload_consul_server.instance_public_ip}"
}

output "instance_public_ip" {
  value = module.payload_consul_server.instance_public_ip
}

output "instance_id" {
  value = module.payload_consul_server.instance_id
}
