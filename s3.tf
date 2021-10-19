resource "aws_s3_bucket" "this" {
  bucket = "${var.name}-${var.environment}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
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
