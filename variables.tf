variable "name" {
  type        = string
  description = "Name of the application."
}

variable "environment" {
  type        = string
  description = "Name of the deploy environment"
}

variable "hosted_zone_name" {
  type        = string
  description = "Name of AWS Route53 Hosted Zone for DNS."
  default     = ""
}

variable "fqdn_alias" {
  type        = string
  description = <<-DESC
    ALIAS for the Cloudfront distribution, S3, and Cognito. Must be in the form of `example.com`.
  DESC
  default     = ""
}

variable "stripe_api_key" {
  type        = string
  description = "API Key for Stripe."
  sensitive   = true
}
