module "ecr" {
  source  = "cloudposse/ecr/aws"
  version = "v0.32.3"

  enabled                 = true
  stage                   = var.environment
  name                    = var.name
  use_fullname            = false
  image_names             = formatlist("${var.name}/%s", concat(["scratch"], keys(local.lambdas)))
  principals_full_access  = []
  image_tag_mutability    = "IMMUTABLE"
  scan_images_on_push     = true
  enable_lifecycle_policy = true
  max_image_count         = 5
}
