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

// TODO: implement least permissive policy
data "aws_iam_policy_document" "appsync_datasource" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = [aws_dynamodb_table.this.arn, "${aws_dynamodb_table.this.arn}/index/${local.gsi_name}"]
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
  }
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
      type = "AWS"
      identifiers = concat(
        [aws_iam_role.appsync.arn],
        module.cloudfront.cloudfront_origin_access_identity_iam_arns
      )
    }
  }
}
