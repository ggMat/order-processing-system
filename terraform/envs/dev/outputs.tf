output "environment" {
  value       = var.environment
  description = "Current environment name"
}

# add outputs as modules are built, e.g.:
# output "api_gateway_url" {
#   value = module.api_gateway.invoke_url
# }
