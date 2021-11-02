resource "aws_appsync_graphql_api" "this" {
  name                = "${local.name}_appsync"
  authentication_type = "API_KEY"
  schema              = file("${path.root}/graphql/schema.graphql")

  # additional_authentication_provider {
  #   authentication_type = "AMAZON_COGNITO_USER_POOLS"

  #   user_pool_config {
  #     aws_region = data.aws_region.current.name
  #     # default_action = "DENY"
  #     user_pool_id = aws_cognito_user_pool.this.id
  #   }
  # }


  # dynamic "additional_authentication_provider" {
  #   for_each = var.environment == "dev" ? [var.environment] : []

  #   content {
  #     authentication_type = "API_KEY"
  #   }
  # }
}

resource "time_rotating" "after_7_days" {
  rotation_days = 7
}

resource "aws_appsync_api_key" "this" {
  depends_on = [time_rotating.after_7_days]

  api_id      = aws_appsync_graphql_api.this.id
  description = "API Key for ${var.name} ${var.environment}"
}

resource "aws_appsync_datasource" "dynamodb" {
  name             = "${local.name}_dynamodb_datasource"
  api_id           = aws_appsync_graphql_api.this.id
  service_role_arn = aws_iam_role.this.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.this.name
  }
}
