# ──────────────────────────────────────────
# SNS topic — receives events from EventBridge
# and fans out to email/webhook subscribers
# ──────────────────────────────────────────

resource "aws_sns_topic" "orders" {
  name = "${var.prefix}-orders"

  # Encrypt messages at rest
  kms_master_key_id = "alias/aws/sns"
}

# ──────────────────────────────────────────
# Topic policy — allows EventBridge to publish
# Without this, EventBridge's rule target will
# be denied even if the IAM role allows it
# ──────────────────────────────────────────

resource "aws_sns_topic_policy" "orders" {
  arn = aws_sns_topic.orders.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.orders.arn
      }
    ]
  })
}

# ──────────────────────────────────────────
# Email subscriptions
# Each address gets a confirmation email —
# it must be confirmed before messages are delivered
# ──────────────────────────────────────────

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.email_endpoints)

  topic_arn = aws_sns_topic.orders.arn
  protocol  = "email"
  endpoint  = each.value
}

# ──────────────────────────────────────────
# HTTPS webhook subscriptions
# SNS will POST a JSON payload to each URL
# The endpoint must respond with 2xx within 15s
# ──────────────────────────────────────────

resource "aws_sns_topic_subscription" "webhook" {
  for_each = toset(var.webhook_endpoints)

  topic_arn            = aws_sns_topic.orders.arn
  protocol             = "https"
  endpoint             = each.value
  endpoint_auto_confirms = true # SNS will auto-confirm the subscription URL
}

# ──────────────────────────────────────────
# CloudWatch alarm — failed deliveries
# Fires when SNS cannot deliver to any subscriber
# ──────────────────────────────────────────

# resource "aws_cloudwatch_metric_alarm" "failed_deliveries" {
#   alarm_name          = "${var.prefix}-sns-failed-deliveries"
#   alarm_description   = "SNS is failing to deliver order notifications"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "NumberOfNotificationsFailed"
#   namespace           = "AWS/SNS"
#   period              = 60
#   statistic           = "Sum"
#   threshold           = 0
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#     TopicName = aws_sns_topic.orders.name
#   }
# }
