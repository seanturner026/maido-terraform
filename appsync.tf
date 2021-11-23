resource "aws_appsync_graphql_api" "this" {
  name                = "${local.name}_appsync"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  schema              = file("${path.root}/graphql/schema.graphql")

  user_pool_config {
    aws_region     = data.aws_region.current.name
    default_action = "DENY"
    user_pool_id   = aws_cognito_user_pool.this.id
  }
}

resource "aws_appsync_datasource" "dynamodb" {
  name             = "${local.name}_dynamodb_datasource"
  api_id           = aws_appsync_graphql_api.this.id
  service_role_arn = aws_iam_role.appsync.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.this.name
  }
}
