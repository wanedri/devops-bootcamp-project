variable "aws_region" {
  description = "Region for all resources. Must match the region in the backend block (backends can't read variables, so that one stays literal)."
  type        = string
  default     = "ap-southeast-1"
}

variable "student_name" {
  description = "Suffix for globally-unique names, per the spec's <nama> placeholder."
  type        = string
  default     = "adri"
}

variable "ssh_key_parameter" {
  description = <<-EOT
    SSM Parameter Store path holding the wan-adri-key PRIVATE key, as a
    SecureString. The Ansible controller fetches it at runtime so it can SSH
    to the web and monitoring servers. Terraform only scopes IAM against this
    path - it never reads the value.
  EOT
  type        = string
  default     = "/devops-bootcamp-2026/ansible-ssh-key"
}

variable "cloudflared_token_parameter" {
  description = <<-EOT
    SSM Parameter Store path holding the Cloudflare Tunnel token.
    Terraform only uses this to scope an IAM policy - it never reads the
    value, so the token never lands in state. The monitoring server
    fetches it at runtime with its own role.
  EOT
  type        = string
  default     = "/devops-bootcamp-2026/tunnel-token"
}
