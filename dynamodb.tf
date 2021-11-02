resource "aws_dynamodb_table" "this" {
  name         = "${local.name}_table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "DK1"
    type = "S"
  }

  global_secondary_index {
    name            = local.gsi_name
    hash_key        = "SK"
    range_key       = "DK1"
    projection_type = "ALL"
  }
}
