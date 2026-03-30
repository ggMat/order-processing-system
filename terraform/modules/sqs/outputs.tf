# These outputs are consumed by other modules via envs/dev/main.tf
# Pattern: module.sqs.<output_name>

output "queue_arn" {
  value       = aws_sqs_queue.orders.arn
  description = "ARN of the main orders queue — used by Lambda worker trigger and IAM role"
}

output "queue_url" {
  value       = aws_sqs_queue.orders.id
  description = "URL of the main orders queue — used by create-order Lambda to send messages"
}

output "queue_name" {
  value       = aws_sqs_queue.orders.name
  description = "Name of the main orders queue — used for CloudWatch dimensions"
}

output "dlq_arn" {
  value       = aws_sqs_queue.dlq.arn
  description = "ARN of the dead letter queue — used for CloudWatch alarms and monitoring"
}

output "dlq_url" {
  value       = aws_sqs_queue.dlq.id
  description = "URL of the dead letter queue"
}

output "dlq_name" {
  value       = aws_sqs_queue.dlq.name
  description = "Name of the dead letter queue — used for CloudWatch dimensions"
}
