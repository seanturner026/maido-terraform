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
data "aws_iam_policy_document" "appsync_dynamodb_datasource" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = [aws_dynamodb_table.this.arn, "${aws_dynamodb_table.this.arn}/index/${local.gsi_name}"]
  }
}

// TODO: security improvements
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
}
