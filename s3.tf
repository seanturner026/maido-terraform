resource "aws_s3_bucket" "this" {
  bucket        = "${var.name}-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = [var.fqdn_alias]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "time_sleep" "wait_5_seconds" {
  depends_on = [aws_s3_bucket.this]

  create_duration = "5s"
}

resource "aws_s3_bucket_policy" "this" {
  depends_on = [time_sleep.wait_5_seconds]
  bucket     = aws_s3_bucket.this.id
  policy     = data.aws_iam_policy_document.bucket.json
}
