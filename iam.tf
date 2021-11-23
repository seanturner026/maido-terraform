resource "aws_iam_role" "appsync" {
  name               = "${local.name}_appsync_datasource_role"
  assume_role_policy = data.aws_iam_policy_document.appsync_trust.json
}

resource "aws_iam_role_policy" "appsync" {
  name   = "${local.name}_appsync_datasource"
  role   = aws_iam_role.appsync.id
  policy = data.aws_iam_policy_document.appsync_datasource.json
}

resource "aws_iam_role" "cognito_unauth" {
  name               = "${local.name}_cognito_unauth_role"
  assume_role_policy = data.aws_iam_policy_document.cognito_unauth_trust.json
}

resource "aws_iam_role_policy" "cognito_unauth" {
  name   = "${local.name}_cognito_unauth"
  role   = aws_iam_role.cognito_unauth.id
  policy = data.aws_iam_policy_document.cognito_unauth.json
}
