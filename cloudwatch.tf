resource "aws_cloudwatch_log_group" "this" {
  for_each = local.lambdas

  name              = "/aws/lambda/${var.name}_${each.key}"
  retention_in_days = 7
}
