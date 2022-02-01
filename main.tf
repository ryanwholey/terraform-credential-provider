
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
