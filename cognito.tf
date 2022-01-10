resource "aws_cognito_user_pool" "this" {
  name                     = local.name
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  admin_create_user_config {
    invite_message_template {
      email_subject = "${title(var.name)} New User Signup"
      email_message = file("${path.root}/assets/cognito_invite_template.html")
      sms_message   = <<-MESSAGE
        username: {username}
        password: {####}
      MESSAGE
    }
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  password_policy {
    minimum_length                   = 20
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    require_uppercase                = true
    temporary_password_validity_days = 10
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "stripe_customer_id"
    required                 = false

    string_attribute_constraints {
      min_length = 6
      max_length = 255
    }
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name                                 = local.name
  user_pool_id                         = aws_cognito_user_pool.this.id
  generate_secret                      = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = [var.hosted_zone_name != "" && var.fqdn_alias != "" ? "https://${var.fqdn_alias}" : "https://${module.cloudfront.cloudfront_distribution_domain_name}"]

  explicit_auth_flows = [
    # "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    # "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    # "ALLOW_USER_SRP_AUTH",
  ]
}

resource "aws_cognito_user_pool_client" "dev" {
  count = var.environment == "dev" ? 1 : 0

  name                                 = "${local.name}_appsync_testing"
  user_pool_id                         = aws_cognito_user_pool.this.id
  generate_secret                      = false
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = [var.hosted_zone_name != "" && var.fqdn_alias != "" ? "https://${var.fqdn_alias}" : "https://${module.cloudfront.cloudfront_distribution_domain_name}"]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
}

resource "aws_cognito_identity_pool" "this" {
  identity_pool_name               = local.name
  allow_unauthenticated_identities = true

  cognito_identity_providers {
    client_id     = aws_cognito_user_pool_client.this.id
    provider_name = aws_cognito_user_pool.this.endpoint
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "this" {
  identity_pool_id = aws_cognito_identity_pool.this.id

  roles = {
    "unauthenticated" = aws_iam_role.cognito_unauth.arn
  }
}

resource "aws_cognito_user_group" "this" {
  name         = "customers"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Customer group for ${local.name}"
  # role_arn     = aws_iam_role.group_role.arn
}
