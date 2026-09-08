# Terraform writes the file Ansible reads, so the inventory can never drift
# from what was actually deployed. This is what the `local` provider in
# providers.tf is for.
#
# The rendered file is committed to git on purpose: Ansible runs on the
# controller, which gets this repo by `git clone`, not by running Terraform.
resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory.ini"

  content = templatefile("${path.module}/inventory.ini.tftpl", {
    web_ip        = module.web_server.private_ip
    monitoring_ip = module.monitoring_server.private_ip
  })
}
