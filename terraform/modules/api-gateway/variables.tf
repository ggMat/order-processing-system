variable "prefix" {
  type        = string
  description = "Resource name prefix, e.g. order-processing-system-dev"
}

variable "environment" {
  type        = string
  description = "Environment name — used as the API Gateway stage name"
}

variable "create_order_invoke_arn" {
  type        = string
  description = "Lambda invoke ARN for create-order — from module.lambda_create_order.invoke_arn"
}

variable "create_order_function_name" {
  type        = string
  description = "Lambda function name for create-order — used to grant API Gateway invoke permission"
}

variable "log_retention_days" {
  type        = number
  description = "Retention period for API Gateway access logs"
  default     = 7
}

variable "throttling_burst_limit" {
  type        = number
  description = "Max concurrent requests API Gateway allows before throttling"
  default     = 50

  validation {
    condition     = var.throttling_burst_limit >= 0
    error_message = "throttling_burst_limit must be >= 0."
  }
}

variable "throttling_rate_limit" {
  type        = number
  description = "Max steady-state requests per second before throttling"
  default     = 100

  validation {
    condition     = var.throttling_rate_limit >= 0
    error_message = "throttling_rate_limit must be >= 0."
  }
}
