# ──────────────────────────────────────────
# Custom event bus
#
# We use a dedicated bus instead of the default one so that:
# - our events are isolated from AWS service events
# - IAM policies can be scoped to this bus only
# - archive and replay can be configured independently
# ──────────────────────────────────────────

resource "aws_cloudwatch_event_bus" "orders" {
  name = "${var.prefix}-orders"
}

# ──────────────────────────────────────────
# Archive
#
# When enabled, every event on the bus is persisted.
# This lets you replay past events — e.g. reprocess all
# FAILED orders from the last 24h after a bug fix.
# ──────────────────────────────────────────

resource "aws_cloudwatch_event_archive" "orders" {
  count = var.enable_archive ? 1 : 0

  name             = "${var.prefix}-orders-archive"
  event_source_arn = aws_cloudwatch_event_bus.orders.arn
  retention_days   = var.archive_retention_days

  event_pattern = jsonencode({
    source = [{ "prefix" = "" }]
  })
}

# ──────────────────────────────────────────
# IAM role — allows EventBridge to publish to SNS
#
# Defined here (not in the IAM module) because it is
# tightly coupled to this bus and these rules.
# The IAM module manages Lambda execution roles only.
# ──────────────────────────────────────────

resource "aws_iam_role" "eventbridge_sns" {
  name = "${var.prefix}-eventbridge-sns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_sns" {
  name = "${var.prefix}-eventbridge-sns-publish"
  role = aws_iam_role.eventbridge_sns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = var.sns_topic_arn
    }]
  })
}

# ──────────────────────────────────────────
# Rule — order.completed
# ──────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "order_completed" {
  name           = "${var.prefix}-order-completed"
  description    = "Matches order.completed events from the worker Lambda"
  event_bus_name = aws_cloudwatch_event_bus.orders.name

  event_pattern = jsonencode({
    source      = [var.order_event_source]
    detail-type = ["order.completed"]
  })
}

resource "aws_cloudwatch_event_target" "order_completed_sns" {
  rule           = aws_cloudwatch_event_rule.order_completed.name
  event_bus_name = aws_cloudwatch_event_bus.orders.name
  target_id      = "OrderCompletedSNS"
  arn            = var.sns_topic_arn
  role_arn       = aws_iam_role.eventbridge_sns.arn
}

# ──────────────────────────────────────────
# Rule — order.failed
# ──────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "order_failed" {
  name           = "${var.prefix}-order-failed"
  description    = "Matches order.failed events from the worker Lambda"
  event_bus_name = aws_cloudwatch_event_bus.orders.name

  event_pattern = jsonencode({
    source      = [var.order_event_source]
    detail-type = ["order.failed"]
  })
}

resource "aws_cloudwatch_event_target" "order_failed_sns" {
  rule           = aws_cloudwatch_event_rule.order_failed.name
  event_bus_name = aws_cloudwatch_event_bus.orders.name
  target_id      = "OrderFailedSNS"
  arn            = var.sns_topic_arn
  role_arn       = aws_iam_role.eventbridge_sns.arn
}

# ──────────────────────────────────────────
# CloudWatch alarms
# ──────────────────────────────────────────

# resource "aws_cloudwatch_metric_alarm" "failed_invocations" {
#   alarm_name          = "${var.prefix}-eventbridge-failed-invocations"
#   alarm_description   = "EventBridge is failing to deliver events to SNS"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "FailedInvocations"
#   namespace           = "AWS/Events"
#   period              = 60
#   statistic           = "Sum"
#   threshold           = 0
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#     EventBusName = aws_cloudwatch_event_bus.orders.name
#   }
# }
#
# resource "aws_cloudwatch_metric_alarm" "throttled_rules" {
#   alarm_name          = "${var.prefix}-eventbridge-throttled"
#   alarm_description   = "EventBridge rules are being throttled"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "ThrottledRules"
#   namespace           = "AWS/Events"
#   period              = 60
#   statistic           = "Sum"
#   threshold           = 0
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#     EventBusName = aws_cloudwatch_event_bus.orders.name
#   }
# }
