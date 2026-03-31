output "function_name" {
  value       = aws_lambda_function.this.function_name
  description = "Full Lambda function name — used by API Gateway integration and CloudWatch"
}

output "function_arn" {
  value       = aws_lambda_function.this.arn
  description = "Lambda function ARN — used by API Gateway to invoke the function"
}

output "invoke_arn" {
  value       = aws_lambda_function.this.invoke_arn
  description = "Lambda invoke ARN — used specifically by API Gateway integration URI"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.lambda.name
  description = "CloudWatch log group name — useful for querying logs in CI/CD or dashboards"
}
