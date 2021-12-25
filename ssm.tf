resource "aws_ssm_parameter" "stripe_api_key" {
  name  = "/${var.name}/stripe/api_key"
  type  = "SecureString"
  value = var.stripe_api_key
}
