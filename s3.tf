resource "aws_s3_bucket" "this" {
  bucket        = "${var.name}-${var.environment}"
  acl           = "public-read"
  force_destroy = true


  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = [var.fqdn_alias]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = "index.html"
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
