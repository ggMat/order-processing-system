output "table_name" {
  value       = aws_dynamodb_table.orders.name
  description = "Table name — used as env var in Lambda functions"
}

output "table_arn" {
  value       = aws_dynamodb_table.orders.arn
  description = "Table ARN — used in IAM role policies to grant Lambda read/write access"
}

output "status_gsi_name" {
  value       = "status-created_at-index"
  description = "GSI name — used by Lambda queries filtering orders by status"
}

output "customer_gsi_name" {
  value       = "customer_id-created_at-index"
  description = "GSI name — used by Lambda queries filtering orders by customer"
}

