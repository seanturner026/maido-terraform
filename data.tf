data "aws_caller_identity" "current" {}
data "aws_ecr_authorization_token" "token" {}
data "aws_region" "current" {}

data "aws_route53_zone" "this" {
  count = var.hosted_zone_name != "" ? 1 : 0

  name         = var.hosted_zone_name
  private_zone = false
}

data "aws_iam_policy_document" "appsync_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["appsync.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "appsync_datasource" {
  statement {
    effect    = "Allow"
    actions   = ["cognito-idp:AdminCreateUser"]
    resources = [aws_cognito_user_pool.this.arn]
  }

  // TODO: implement least permissive policy
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:*",
    ]
    resources = [aws_dynamodb_table.this.arn, "${aws_dynamodb_table.this.arn}/index/${local.gsi_name}"]
  }

  # statement {
  #   effect    = "Allow"
  #   actions   = ["lambda:InvokeFunction"]
  #   resources = [aws_lambda_function.this["stripe_update_payment_method"].arn]
  # }

  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.target.arn, aws_sqs_queue.deadletter.arn]
  }
}

data "aws_iam_policy_document" "appsync_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cognito_unauth_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["unauthenticated"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.this.id]
    }

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cognito_unauth" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:query"]
    resources = [aws_dynamodb_table.this.arn, "${aws_dynamodb_table.this.arn}/index/${local.gsi_name}"]

    # condition {
    #   test     = "ForAllValues:StringEquals"
    #   variable = "dynamodb:LeadingKeys"
    #   values   = ["PRODUCT#*"]
    # }
  }

  # statement {
  #   effect    = "Allow"
  #   actions   = ["s3:GetObject"]
  #   resources = ["${aws_s3_bucket.this.arn}/products/assets/*"]
  # }
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid       = "EnforceHTTPS"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = module.cloudfront.cloudfront_origin_access_identity_iam_arns
    }
  }
}

data "aws_iam_policy_document" "lambda_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  for_each = local.lambdas

  statement {
    sid       = "CreateCloudWatchLogGroup"
    effect    = "Allow"
    actions   = ["logs:PutLogEvents", "logs:CreateLogStream"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:log-group:/aws/lambda/${aws_lambda_function.this[each.key].function_name}*"]
  }

  dynamic "statement" {
    for_each = each.value.iam_statements
    iterator = s

    content {
      actions   = s.value.actions
      resources = s.value.resources
    }
  }
}
