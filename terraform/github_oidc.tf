# Lets GitHub Actions push to ECR without any long-lived access keys.
#
# GitHub presents a short-lived OIDC token; AWS verifies it came from this
# specific repository and trades it for temporary credentials. Nothing secret
# is stored in the repository or in GitHub's settings - only the role ARN,
# which is not sensitive.

# Only one provider for this issuer may exist per AWS account. If you already
# created one (for another project, or by hand), set
# create_github_oidc_provider = false and this looks the existing one up.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = { Name = "github-actions-oidc" }
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_arn = var.create_github_oidc_provider ? (
    aws_iam_openid_connect_provider.github[0].arn
    ) : (
    data.aws_iam_openid_connect_provider.github[0].arn
  )
}

# The sub condition is what stops any other repository on GitHub from assuming
# this role. Without it, the trust policy would accept a token from anyone.
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:*"]
    }
  }
}

# Push and pull on this one repository. GetAuthorizationToken cannot be scoped
# to a resource - that is an AWS limitation, not an oversight.
data "aws_iam_policy_document" "github_actions_ecr" {
  statement {
    sid       = "GetAuthorizationToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PushAndPullThisRepository"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [aws_ecr_repository.app.arn]
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "devops-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json

  tags = { Name = "devops-github-actions-role" }
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name   = "devops-github-actions-ecr"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_ecr.json
}
