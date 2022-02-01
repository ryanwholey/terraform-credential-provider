
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
      key       = "OKTA_API_TOKEN"
      value     = data.kms_secrets.secrets["OKTA_API_TOKEN"].value
      sensitive = true
    },
    {
      key       = "OKTA_BASE_URL"
      value     = "okta.com"
      sensitive = false
    },
    {
      key       = "OKTA_ORG_NAME"
      value     = "dev-446678"
      sensitive = false
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

provider "aws" {}
