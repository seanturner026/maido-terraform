provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      application_name = var.name
      environment      = var.environment
    }
  }
}

# provider "docker" {
#   registry_auth {
#     address  = local.ecr_address
#     username = data.aws_ecr_authorization_token.token.user_name
#     password = data.aws_ecr_authorization_token.token.password
#   }
# }
