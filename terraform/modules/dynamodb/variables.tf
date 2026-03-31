variable "prefix" {
  type        = string
  description = "Resource name prefix, e.g. order-processing-system-dev"
}

variable "billing_mode" {
  type        = string
  description = "PAY_PER_REQUEST (on-demand) or PROVISIONED"
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "read_capacity" {
  type        = number
  description = "Read capacity units — only used when billing_mode is PROVISIONED"
  default     = null
}

variable "write_capacity" {
  type        = number
  description = "Write capacity units — only used when billing_mode is PROVISIONED"
  default     = null
}

variable "ttl_enabled" {
  type        = bool
  description = "Enable TTL to auto-expire old orders"
  default     = false
}

variable "ttl_attribute" {
  type        = string
  description = "Attribute name used for TTL expiry (must be a Number type)"
  default     = "expires_at"
}

variable "point_in_time_recovery" {
  type        = bool
  description = "Enable point-in-time recovery (recommended for prod)"
  default     = false
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention for DynamoDB-related logs"
  default     = 7
}
