locals {
  gsi_name = "GSI1"
  name     = "${var.name}_${var.environment}"

  appsync = {
    resolvers = [
      {
        field       = "createCognitoUser"
        type        = "Mutation"
        data_source = aws_cloudformation_stack.appsync_cognito_data_source.outputs.name
        extra_data = {
          user_pool_id = aws_cognito_user_pool.this.id
        }
        }, {
        field       = "getMaidoTable"
        type        = "Query"
        data_source = aws_appsync_datasource.dynamodb.name
        }, {
        field       = "queryMaidoTablesByGSI1"
        type        = "Query"
        data_source = aws_appsync_datasource.dynamodb.name
      }
    ]
  }

  resolvers_map = {
    for resolver in local.appsync.resolvers : lower("${resolver.type}_${resolver.field}") => resolver
  }
}
