provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      application_name = var.name
      environment      = var.environment
    }
  }
}

provider "docker" {
  registry_auth {
    address  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}
