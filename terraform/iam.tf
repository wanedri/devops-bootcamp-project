# Each instance gets its own role so permissions stay minimal:
#   web        - SSM + pull from ECR
#   ansible    - SSM only
#   monitoring - SSM + read the tunnel token
# All three share the same trust policy: "EC2 may assume this role".

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# This managed policy is what lets Session Manager reach an instance.
# Without it on all three, you cannot open a shell on the private boxes.
locals {
  ssm_core_policy = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ---------------------------------------------------------------- web server

resource "aws_iam_role" "web" {
  name               = "devops-web-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = { Name = "devops-web-role" }
}

resource "aws_iam_role_policy_attachment" "web_ssm" {
  role       = aws_iam_role.web.name
  policy_arn = local.ssm_core_policy
}

# The web server pulls its own image at deploy time.
# NOTE: read-only per the spec. If you end up building and pushing the image
# *on this box* rather than elsewhere, this needs to become
# AmazonEC2ContainerRegistryPowerUser - ReadOnly cannot push.
resource "aws_iam_role_policy_attachment" "web_ecr" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "web" {
  name = "devops-web-profile"
  role = aws_iam_role.web.name
}

# --------------------------------------------------------- ansible controller

resource "aws_iam_role" "ansible" {
  name               = "devops-ansible-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = { Name = "devops-ansible-role" }
}

resource "aws_iam_role_policy_attachment" "ansible_ssm" {
  role       = aws_iam_role.ansible.name
  policy_arn = local.ssm_core_policy
}

resource "aws_iam_instance_profile" "ansible" {
  name = "devops-ansible-profile"
  role = aws_iam_role.ansible.name
}

# ---------------------------------------------------------- monitoring server

resource "aws_iam_role" "monitoring" {
  name               = "devops-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = { Name = "devops-monitoring-role" }
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring.name
  policy_arn = local.ssm_core_policy
}

# Scoped to the one parameter holding the tunnel token, not all of SSM.
# kms:Decrypt is needed because the parameter is a SecureString; the
# ViaService condition means this role can only decrypt *through* SSM,
# not against arbitrary KMS keys.
data "aws_iam_policy_document" "monitoring_tunnel_token" {
  statement {
    sid     = "ReadTunnelToken"
    actions = ["ssm:GetParameter", "ssm:GetParameters"]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.my_account.account_id}:parameter${var.cloudflared_token_parameter}",
    ]
  }

  statement {
    sid       = "DecryptSecureStringViaSSM"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "monitoring_tunnel_token" {
  name   = "devops-monitoring-tunnel-token"
  role   = aws_iam_role.monitoring.id
  policy = data.aws_iam_policy_document.monitoring_tunnel_token.json
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "devops-monitoring-profile"
  role = aws_iam_role.monitoring.name
}
