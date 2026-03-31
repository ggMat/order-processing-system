# create-order Lambda
output "create_order_role_arn" {
  value       = aws_iam_role.create_order.arn
  description = "Execution role ARN for create-order Lambda — passed to lambda module"
}

output "create_order_role_name" {
  value       = aws_iam_role.create_order.name
  description = "Execution role name for create-order Lambda"
}

# worker Lambda
output "worker_role_arn" {
  value       = aws_iam_role.worker.arn
  description = "Execution role ARN for worker Lambda — passed to lambda module"
}

output "worker_role_name" {
  value       = aws_iam_role.worker.name
  description = "Execution role name for worker Lambda"
}
