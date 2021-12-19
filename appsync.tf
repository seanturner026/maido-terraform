resource "aws_appsync_graphql_api" "this" {
  name                = "${local.name}_appsync"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"

  schema = join("\n", [
    for schema in fileset("${path.root}/graphql/schemas", "*.graphql")
    : file("${path.root}/graphql/schemas/${schema}")
  ])

  user_pool_config {
    aws_region     = data.aws_region.current.name
    default_action = "DENY"
    user_pool_id   = aws_cognito_user_pool.this.id
  }

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync.arn
    field_log_level          = "ALL"
    exclude_verbose_content  = false
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

// Replace with terraform one day...
//
// https://github.com/hashicorp/terraform-provider-aws/issues/12721#issuecomment-787146303
resource "aws_cloudformation_stack" "appsync_cognito_data_source" {
  name          = "AppSyncCognitoDataSource"
  template_body = <<-STACK
    Resources:
      AppsyncCognitoHttpDataSource:
          Type: AWS::AppSync::DataSource
          Properties:
            ApiId: ${aws_appsync_graphql_api.this.id}
            Name: "${local.name}_http_cognito"
            Type: HTTP
            ServiceRoleArn: ${aws_iam_role.appsync.arn}
            HttpConfig:
              Endpoint: !Sub https://cognito-idp.$${AWS::Region}.amazonaws.com/
              AuthorizationConfig:
                AuthorizationType: AWS_IAM
                AwsIamConfig:
                  SigningRegion: !Ref AWS::Region
                  SigningServiceName: cognito-idp
    Outputs:
      name:
        Value: "${local.name}_http_cognito"
  STACK
}

# resource "aws_appsync_datasource" "http" {
#   for_each = {
#     cognito_idp = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/"
#   }

#   name             = "${local.name}_http_${each.key}"
#   api_id           = aws_appsync_graphql_api.this.id
#   service_role_arn = aws_iam_role.appsync.arn
#   type             = "HTTP"

#   http_config {
#     endpoint = each.value
#   }
# }
