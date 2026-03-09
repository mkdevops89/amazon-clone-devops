# ==========================================
# Amazon Cognito (Identity & Access Management)
# ==========================================

resource "aws_cognito_user_pool" "pool" {
  name = "devcloudproject-user-pool"

  # Allow users to sign in with their email address
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Your verification code for DevCloudProject"
    email_message        = "Your verification code is {####}."
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 5
      max_length = 2048
    }
  }

  tags = {
    Environment = "Dev"
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "auth-devcloudproject"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "client" {
  name = "devcloudproject-app-client"

  user_pool_id = aws_cognito_user_pool.pool.id

  # OAuth settings required for Hosted UI
  generate_secret                      = false # False for public SPA/React apps
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = [
    "https://www.devcloudproject.com/auth/callback",
    "http://localhost:3000/auth/callback"
  ]
  
  logout_urls = [
    "https://www.devcloudproject.com",
    "http://localhost:3000"
  ]
}

# ==========================================
# Export to Systems Manager (SSM) for Jenkins
# ==========================================

resource "aws_ssm_parameter" "cognito_user_pool_id" {
  name        = "/devcloudproject/prod/cognito/user_pool_id"
  description = "Cognito User Pool ID"
  type        = "String"
  value       = aws_cognito_user_pool.pool.id
}

resource "aws_ssm_parameter" "cognito_app_client_id" {
  name        = "/devcloudproject/prod/cognito/app_client_id"
  description = "Cognito App Client ID"
  type        = "String"
  value       = aws_cognito_user_pool_client.client.id
}

resource "aws_ssm_parameter" "cognito_domain" {
  name        = "/devcloudproject/prod/cognito/domain"
  description = "Cognito Hosted UI Domain"
  type        = "String"
  value       = "${aws_cognito_user_pool_domain.main.domain}.auth.${var.region}.amazoncognito.com"
}
