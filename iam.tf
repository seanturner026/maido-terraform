resource "aws_iam_role" "this" {
  name               = "${local.name}_appsync_datasource_role"
  assume_role_policy = data.aws_iam_policy_document.appsync_trust.json
}

resource "aws_iam_role_policy" "this" {
  name   = "${local.name}_appsync_datasource"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.appsync_datasource.json
}
