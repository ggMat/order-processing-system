output "environment" {
  value       = var.environment
  description = "Current environment name"
}

output "api_endpoint" {
  value       = module.api_gateway.api_endpoint
  description = "POST /orders endpoint — use this to test the system"
}
