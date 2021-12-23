resource "aws_sqs_queue" "target" {
  name                      = "${local.name}_onboarding_queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  sqs_managed_sse_enabled   = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "deadletter" {
  name                      = "${local.name}_onboarding_deadletter_queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  sqs_managed_sse_enabled   = true
}
