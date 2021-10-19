resource "aws_appsync_graphql_api" "this" {
  name                = "${var.name}_${var.environment}_appsync"
  authentication_type = "API_KEY"
  schema              = file("${path.root}/graphql/schema.graphql")
}

resource "aws_appsync_api_key" "this" {
  api_id      = aws_appsync_graphql_api.this.id
  description = "API Key for ${var.name} ${var.environment}"
}

resource "aws_appsync_datasource" "this" {
  name             = "${var.name}_dynamodb_datasource"
  api_id           = aws_appsync_graphql_api.this.id
  service_role_arn = aws_iam_role.this.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.this.name
  }
}
