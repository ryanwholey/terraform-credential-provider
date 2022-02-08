resource "aws_kms_key" "secrets" {}

output "key_id" {
  value = aws_kms_key.secrets.id
}

# output "secrets" {
#   sensitive = true
#   value     = data.aws_kms_secrets.secrets
# }

# output "variables" {
#   sensitive = true
#   value = [
#     {
#       key         = "OKTA_API_TOKEN"
#       value       = data.aws_kms_secrets.secrets.plaintext["okta_api_token"]
#       sensitive   = true
#       category    = "env"
#       description = "An Okta API token"
#     },
#     {
#       key         = "OKTA_BASE_URL"
#       value       = "okta.com"
#       sensitive   = false
#       category    = "env"
#       description = "The base Okta URL"
#     },
#     {
#       key         = "OKTA_ORG_NAME"
#       value       = "dev-446678"
#       sensitive   = false
#       category    = "env"
#       description = "The Okta organization name"
#     },
#   ]
# }

terraform {
  required_version = ">= 1, < 2"

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "ryanwholey"

    workspaces {
      name = "terraform-credential-provider"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4"
    }
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "ryanwholey-test-terraform-state"
}

data "aws_iam_policy_document" "assume" {
  statement {
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ryanwholey/*"]
    }
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

data "aws_iam_policy_document" "operator" {
  statement {
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
  }
}

resource "aws_iam_role" "state" {
  name               = "test-terraform-state"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  inline_policy {
    name   = "state-operator"
    policy = data.aws_iam_policy_document.operator.json
  }
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = data.tls_certificate.github.url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

resource "aws_s3_bucket_object" "object" {
  bucket  = aws_s3_bucket.state.bucket
  key     = "object"
  content = "content"
}
