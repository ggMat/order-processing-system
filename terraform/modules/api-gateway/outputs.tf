output "api_endpoint" {
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/orders"
  description = "Full URL for the POST /orders endpoint — use this to test the system"
}

output "api_id" {
  value       = aws_apigatewayv2_api.orders.id
  description = "API Gateway API ID — used for CloudWatch dimensions and debugging"
}

output "stage_name" {
  value       = aws_apigatewayv2_stage.default.name
  description = "API Gateway stage name"
}

output "execution_arn" {
  value       = aws_apigatewayv2_api.orders.execution_arn
  description = "Execution ARN — base for scoping Lambda invoke permissions"
}
