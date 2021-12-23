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

  # log_config {
  #   cloudwatch_logs_role_arn = aws_iam_role.appsync.arn
  #   field_log_level          = "ALL"
  #   exclude_verbose_content  = false
  # }
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

# resource "aws_appsync_datasource" "lambda" {
#   name             = "${local.name}_lambda_datasource"
#   api_id           = aws_appsync_graphql_api.this.id
#   service_role_arn = aws_iam_role.appsync.arn
#   type             = "AWS_LAMBDA"
# }

// Replace with terraform one day...
//
// https://github.com/hashicorp/terraform-provider-aws/issues/12721#issuecomment-787146303
resource "aws_cloudformation_stack" "appsync_data_sources" {
  name          = "AppSyncDataSources"
  template_body = <<-STACK
    Resources:
      AppsyncCognitoHttpDataSource:
          Type: AWS::AppSync::DataSource
          Properties:
            ApiId: ${aws_appsync_graphql_api.this.id}
            Name: "${local.name}_http_cognito"
            Description: Cognito Identity Data Source
            Type: HTTP
            ServiceRoleArn: ${aws_iam_role.appsync.arn}
            HttpConfig:
              Endpoint: !Sub https://cognito-idp.$${AWS::Region}.amazonaws.com/
              AuthorizationConfig:
                AuthorizationType: AWS_IAM
                AwsIamConfig:
                  SigningRegion: !Ref AWS::Region
                  SigningServiceName: cognito-idp

      SQSHttpDataSource:
        Type: AWS::AppSync::DataSource
        Properties:
          ApiId: ${aws_appsync_graphql_api.this.id}
          Name: "${local.name}_http_sqs"
          Description: SQS Data Source
          Type: HTTP
          ServiceRoleArn: ${aws_iam_role.appsync.arn}
          HttpConfig:
            Endpoint: !Sub https://sqs.$${AWS::Region}.amazonaws.com/
            AuthorizationConfig:
              AuthorizationType: AWS_IAM
              AwsIamConfig:
                SigningRegion: !Ref AWS::Region
                SigningServiceName: sqs
    Outputs:
      cognitoName:
        Value: "${local.name}_http_cognito"
      sqsName:
        Value: "${local.name}_http_sqs"
  STACK

  lifecycle {
    ignore_changes = [template_body]
  }
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


resource "aws_appsync_resolver" "unit" {
  for_each = local.maps.resolvers.unit

  api_id            = aws_appsync_graphql_api.this.id
  field             = each.value.field
  type              = title(each.value.type)
  data_source       = each.value.data_source
  kind              = "UNIT"
  request_template  = templatefile("${path.root}/graphql/request_templates/${each.value.field}.vtl", lookup(each.value, "extra_data", {}))
  response_template = templatefile("${path.root}/graphql/response_templates/${each.value.field}.vtl", lookup(each.value, "extra_data", {}))

  # caching_config {
  #   caching_keys = [
  #     "$context.identity.sub",
  #     "$context.arguments.id",
  #   ]
  #   ttl = 60
  # }
}

resource "aws_appsync_resolver" "pipeline" {
  for_each = local.maps.resolvers.pipeline

  api_id            = aws_appsync_graphql_api.this.id
  field             = each.value.field
  type              = title(each.value.type)
  kind              = "PIPELINE"
  request_template  = "{}"
  response_template = "$util.toJson($ctx.result)"

  pipeline_config {
    functions = [for k in each.value.function_keys : aws_appsync_function.this[k].function_id]
  }
}

resource "aws_appsync_function" "this" {
  for_each = local.appsync.functions

  api_id                    = aws_appsync_graphql_api.this.id
  name                      = each.key
  data_source               = each.value.data_source
  request_mapping_template  = templatefile("${path.root}/graphql/request_templates/${each.key}.vtl", lookup(each.value, "extra_data", {}))
  response_mapping_template = templatefile("${path.root}/graphql/response_templates/${each.key}.vtl", lookup(each.value, "extra_data", {}))
}
