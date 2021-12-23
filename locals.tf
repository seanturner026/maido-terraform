locals {
  gsi_name = "GSI1"
  name     = "${var.name}_${var.environment}"

  appsync = {

    functions = {
      createCognitoUser = {
        data_source = aws_cloudformation_stack.appsync_data_sources.outputs.cognitoName
        extra_data = {
          user_pool_id = aws_cognito_user_pool.this.id
        }
      }
      putUserTable = {
        data_source = aws_appsync_datasource.dynamodb.name
      }
      putQueueCreateStripeCustomer = {
        data_source = aws_cloudformation_stack.appsync_data_sources.outputs.sqsName
        extra_data = {
          account_id = data.aws_caller_identity.current.account_id
          queue_name = aws_sqs_queue.target.name
        }
      }
    }

    resolvers = {
      pipeline = [
        {
          field         = "onboardUser"
          type          = "mutation"
          data_source   = aws_cloudformation_stack.appsync_data_sources.outputs.cognitoName
          function_keys = ["createCognitoUser", "putUserTable", "putQueueCreateStripeCustomer"]
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

  lambdas = {
    stripe = {
      description = "Wraps the Stripe API and writes to DynamoDB"
      timeout     = 10
      environment_variables = {
        DYNAMODB_TABLE_ARN = aws_dynamodb_table.this.arn
      }
      iam_statements = {
        dynamodb = {
          actions   = ["dynamodb:DeleteItem", "dynamodb:PutItem", "dynamodb:Query"]
          resources = [aws_dynamodb_table.this.arn]
        }
        sqs = {
          actions   = ["sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
          resources = [aws_sqs_queue.target.arn]
        }
      }
    }
  }

  maps = {
    resolvers = {
      pipeline = {
        for resolver in local.appsync.resolvers.pipeline : lower("${resolver.type}_${resolver.field}") => resolver
      }
      unit = {
        for resolver in local.appsync.resolvers.unit : lower("${resolver.type}_${resolver.field}") => resolver
      }
    }
  }
}
