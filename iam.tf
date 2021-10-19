resource "aws_iam_role" "this" {
  name               = "${var.name}_${var.environment}_dynamodb_datasource_role"
  assume_role_policy = data.aws_iam_policy_document.appsync_trust.json
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}_${var.environment}_dynamodb_datasource"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.appsync_dynamodb_datasource.json
}
