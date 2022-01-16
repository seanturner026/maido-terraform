resource "aws_lambda_function" "this" {
  for_each   = local.lambdas
  depends_on = [module.docker_image]

  function_name = "${var.name}_${each.key}"
  role          = aws_iam_role.lambda[each.key].arn
  architectures = ["arm64"]
  description   = each.value.description
  image_uri     = "${module.ecr.repository_url_map["${var.name}/scratch"]}:scratch"
  package_type  = "Image"
  timeout       = each.value.timeout

  dynamic "environment" {
    for_each = lookup(each.value, "environment_variables", {}) != {} ? [each.value.environment_variables] : []

    content {
      variables = each.value.environment_variables
    }
  }

  lifecycle {
    ignore_changes = [image_uri]
  }
}

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn                   = aws_sqs_queue.target.arn
  function_name                      = aws_lambda_function.this["stripe_onboarding"].arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 0
}

module "docker_image" {
  source  = "terraform-aws-modules/lambda/aws//modules/docker-build"
  version = "v2.28.0"

  create_ecr_repo = false
  ecr_repo        = module.ecr.repository_name
  image_tag       = "scratch"
  scan_on_push    = false
  source_path     = "docker"
}
