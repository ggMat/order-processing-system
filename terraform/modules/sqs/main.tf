# ──────────────────────────────────────────
# Dead Letter Queue
# Created first — the main queue references its ARN
# ──────────────────────────────────────────

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.prefix}-orders-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds

  sqs_managed_sse_enabled = true
}

# ──────────────────────────────────────────
# Main orders queue
# ──────────────────────────────────────────

resource "aws_sqs_queue" "orders" {
  name                       = "${var.prefix}-orders"
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention_seconds

  sqs_managed_sse_enabled = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

# ──────────────────────────────────────────
# Queue policy — allows Lambda service to consume
# ──────────────────────────────────────────

resource "aws_sqs_queue_policy" "orders" {
  queue_url = aws_sqs_queue.orders.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaConsume"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.orders.arn
      }
    ]
  })
}

# ──────────────────────────────────────────
# CloudWatch alarm — fires on any DLQ message
# any message here means a processing failure
# ──────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name          = "${var.prefix}-dlq-not-empty"
  alarm_description   = "Messages are accumulating in the dead letter queue"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1 
  metric_name         = "ApproximateNumberOfMessagesVisible" 
  namespace           = "AWS/SQS"
  period              = 60 
  statistic           = "Sum"
  threshold           = var.alarm_dlq_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name 
  }
}
