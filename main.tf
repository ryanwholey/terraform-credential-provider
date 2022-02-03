resource "aws_kms_key" "secrets" {}

data "aws_kms_secrets" "secrets" {
  dynamic "secret" {
    for_each = local.secrets

    content {
      name    = secret.key
      payload = secret.value
    }
  }
}

output "key_id" {
  value = aws_kms_key.secrets.id
}

output "secrets" {
  sensitive = true
  value     = data.aws_kms_secrets.secrets
}

output "variables" {
  sensitive = true
  value = [
    {
      key         = "OKTA_API_TOKEN"
      value       = data.aws_kms_secrets.secrets.plaintext["OKTA_API_TOKEN"]
      sensitive   = true
      category    = "env"
      description = "An Okta API token"
    },
    {
      key         = "OKTA_BASE_URL"
      value       = "okta.com"
      sensitive   = false
      category    = "env"
      description = "The base Okta URL"
    },
    {
      key         = "OKTA_ORG_NAME"
      value       = "dev-446678"
      sensitive   = false
      category    = "env"
      description = "The Okta organization name"
    },
  ]
}

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
  }
}
