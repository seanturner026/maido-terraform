locals {
  gsi_name = "GSI1"
  name     = "${var.name}_${var.environment}"

  appsync = {
    functions = {
      putCognitoUser = {
        data_source = aws_appsync_datasource.http["cognito_idp"].name
        extra_data = {
          user_pool_id = aws_cognito_user_pool.this.id
        }
      }
      putUserTable = {
        data_source = aws_appsync_datasource.dynamodb.name
      }
      # putOrderTable = {
      #   data_source = aws_appsync_datasource.dynamodb.name
      # }
      putQueueCreateStripeCustomer = {
        data_source = aws_appsync_datasource.http["sqs"].name
        extra_data = {
          account_id = data.aws_caller_identity.current.account_id
          queue_name = aws_sqs_queue.target.name
        }
      }
      putStripePaymentMethod = {
        data_source = aws_appsync_datasource.lambda["stripe_update_payment_method"].name
      }
    }

    resolvers = {
      pipeline = [
        {
          field         = "onboardUser"
          type          = "mutation"
          function_keys = ["putCognitoUser", "putQueueCreateStripeCustomer"]
        },
        # {
        #   field         = "createPayment"
        #   type          = "mutation"
        #   function_keys = ["putQueueCreateStripePayment"]
        # }
      ]
      unit = [
        {
          field       = "getMaidoTable"
          type        = "query"
          data_source = aws_appsync_datasource.dynamodb.name
        },
        {
          field       = "putStripePaymentMethod"
          type        = "mutation"
          data_source = aws_appsync_datasource.lambda["stripe_update_payment_method"].name
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
    stripe_onboarding = {
      description = "Onboards customers with the Stripe API and DynamoDB"
      timeout     = 10
      environment_variables = {
        DYNAMODB_TABLE_NAME = aws_dynamodb_table.this.name
        STRIPE_API_KEY      = aws_ssm_parameter.stripe_api_key.value
        SQS_QUEUE_URL       = aws_sqs_queue.target.url
        USER_POOL_ID        = aws_cognito_user_pool.this.id
      }
      trigger = "sqs"
      iam_statements = {
        cognito = {
          actions   = ["cognito-idp:AdminUpdateUserAttributes"]
          resources = [aws_cognito_user_pool.this.arn]
        }
        dynamodb = {
          actions   = ["dynamodb:BatchWriteItem"]
          resources = [aws_dynamodb_table.this.arn]
        }
        sqs = {
          actions   = ["sqs:DeleteMessage", "sqs:DeleteMessageBatch", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
          resources = [aws_sqs_queue.target.arn]
        }
      }
    }
    stripe_update_payment_method = {
      description = "Creates a default payment method for a customer with the Stripe API"
      timeout     = 10
      environment_variables = {
        STRIPE_API_KEY = aws_ssm_parameter.stripe_api_key.value
      }
      trigger        = "appsync"
      iam_statements = {}
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
