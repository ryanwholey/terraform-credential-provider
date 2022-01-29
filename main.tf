
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

data "aws_iam_policy_document" "decrypt" {
  statement {
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.secrets.arn]
  }
}

resource "aws_iam_user" "updater" {
  name = "terraform-workspace-updater"
}

resource "aws_iam_access_key" "updater" {
  user = aws_iam_user.updater.name
}

resource "aws_iam_user_policy" "updater" {
  name   = "terraform-workspace-updater"
  user   = aws_iam_user.updater.name
  policy = data.aws_iam_policy_document.decrypt.json
}

output "updater" {
  sensitive = true
  value = {
    key_id     = aws_iam_access_key.updater.id
    secret_key = aws_iam_access_key.updater.secret
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
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "ryanwholey"

    workspaces {
      name = "terraform-credential-provider"
    }
  }
}
