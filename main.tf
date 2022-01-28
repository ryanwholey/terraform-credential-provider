
resource "aws_kms_key" "secrets" {}

data "aws_iam_policy_document" "decrypt" {
  statement {
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.secrets.id]
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

output "aws" {
  sensitive = true
  value = {
    key_id     = aws_iam_access_key.updater.id
    secret_key = aws_iam_access_key.updater.secret
  }
}

output "key_id" {
  value = aws_kms_key.secrets.id
}

