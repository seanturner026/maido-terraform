provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      application_name = var.name
      environment      = var.environment
    }
  }
}
