variable "prefix" {
  type        = string
  description = "Resource name prefix, e.g. order-processing-system-dev"
}

variable "function_name" {
  type        = string
  description = "Short function name, appended to prefix. e.g. 'create-order' or 'worker'"
}

variable "handler" {
  type        = string
  description = "Function entrypoint in the format file.method, e.g. 'index.handler'"
  default     = "index.handler"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime identifier"
  default     = "python3.12"

  validation {
    condition = contains([
      "nodejs20.x", "nodejs18.x",
      "python3.12", "python3.11", "python3.10",
      "java21", "java17"
    ], var.runtime)
    error_message = "Runtime must be a supported AWS Lambda runtime."
  }
}

variable "memory_size" {
  type        = number
  description = "Memory allocated to the function in MB"
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 MB and 10240 MB."
  }
}

variable "timeout" {
  type        = number
  description = "Function timeout in seconds"
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "role_arn" {
  type        = string
  description = "IAM execution role ARN — from module.iam.create_order_role_arn or module.iam.worker_role_arn"
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables injected into the function at runtime"
  default     = {}
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log group retention period in days"
  default     = 7
}

# ── SQS trigger (worker only) ────────────
variable "sqs_trigger_enabled" {
  type        = bool
  description = "Set to true for the worker Lambda — creates an SQS event source mapping"
  default     = false
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue to trigger this Lambda — required when sqs_trigger_enabled = true"
  default     = null
}

variable "sqs_batch_size" {
  type        = number
  description = "Max number of SQS messages per Lambda invocation"
  default     = 10

  validation {
    condition     = var.sqs_batch_size >= 1 && var.sqs_batch_size <= 10000
    error_message = "sqs_batch_size must be between 1 and 10000."
  }
}

variable "sqs_max_concurrency" {
  type        = number
  description = "Max concurrent Lambda invocations from SQS. Prevents runaway scaling. null = no limit."
  default     = 5
}
