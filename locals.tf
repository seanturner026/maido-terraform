locals {
  gsi_name = "GSI1"
  name     = "${var.name}_${var.environment}"

  appsync = {

    functions = {
      createCognitoUser = {
        data_source = aws_cloudformation_stack.appsync_cognito_data_source.outputs.name
        extra_data = {
          user_pool_id = aws_cognito_user_pool.this.id
        }
      }
      putUserTable = {
        data_source = aws_appsync_datasource.dynamodb.name
      }
      updateUserTableStripeDetails = {
        data_source = aws_appsync_datasource.dynamodb.name
      }
    }

    resolvers = {
      pipeline = [
        {
          field         = "onboardUser"
          type          = "mutation"
          data_source   = aws_cloudformation_stack.appsync_cognito_data_source.outputs.name
          function_keys = ["createCognitoUser", "putUserTable", "updateUserTableStripeDetails"]
        }
      ]
      unit = [
        {
          field       = "getMaidoTable"
          type        = "query"
          data_source = aws_appsync_datasource.dynamodb.name
        },
        {
          field       = "queryMaidoTablesByGSI1"
          type        = "query"
          data_source = aws_appsync_datasource.dynamodb.name
        }
      ]
    }
  }

  resolvers_map = {
    pipeline = {
      for resolver in local.appsync.resolvers.pipeline : lower("${resolver.type}_${resolver.field}") => resolver
    }
    unit = {
      for resolver in local.appsync.resolvers.unit : lower("${resolver.type}_${resolver.field}") => resolver
    }
  }
}
