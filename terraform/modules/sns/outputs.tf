output "topic_arn" {
  value       = aws_sns_topic.orders.arn
  description = "ARN of the orders SNS topic — used by EventBridge rule as target"
}

output "topic_name" {
  value       = aws_sns_topic.orders.name
  description = "Name of the orders SNS topic — used for CloudWatch dimensions"
}
