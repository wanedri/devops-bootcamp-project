output "web_server_private_ip" {
  description = "Private IP of the web server - the Prometheus scrape target."
  value       = module.web_server.private_ip
}

output "web_server_public_ip" {
  description = "Elastic IP of the web server - point web.haqqki.com here."
  value       = module.web_server.public_ip
}

output "ansible_server_private_ip" {
  description = "Private IP of the Ansible controller."
  value       = module.ansible_server.private_ip
}

output "monitoring_server_private_ip" {
  description = "Private IP of the monitoring server."
  value       = module.monitoring_server.private_ip
}

output "ecr_repository_url" {
  description = "Full repository URL - the image tag target for docker push."
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_registry_url" {
  description = "Registry host, for `docker login`. Built from the account id rather than hardcoded."
  value       = "${data.aws_caller_identity.my_account.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}
