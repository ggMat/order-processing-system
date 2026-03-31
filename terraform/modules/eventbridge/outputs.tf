output "bus_name" {
  value       = aws_cloudwatch_event_bus.orders.name
  description = "Custom event bus name — passed as env var to worker Lambda for publishing events"
}

output "bus_arn" {
  value       = aws_cloudwatch_event_bus.orders.arn
  description = "Custom event bus ARN — used in worker Lambda IAM policy to allow events:PutEvents"
}

output "order_event_source" {
  value       = var.order_event_source
  description = "Event source string — worker Lambda must use this exact value when publishing"
}
