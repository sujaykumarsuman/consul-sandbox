locals {
  ssh_key_path = "${path.module}/../../../shared/ssh/sh-dc-server-key.pem"
}

resource "null_resource" "fix_ssh_key_permissions" {
  provisioner "local-exec" {
    command = "chmod 400 ${local.ssh_key_path}"
  }
}
