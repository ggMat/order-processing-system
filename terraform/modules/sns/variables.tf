variable "prefix" {
  type        = string
  description = "Resource name prefix, e.g. order-processing-system-dev"
}

variable "email_endpoints" {
  type        = list(string)
  description = "List of email addresses to subscribe to order notifications"
  default     = []
}

variable "webhook_endpoints" {
  type        = list(string)
  description = "List of HTTPS webhook URLs to subscribe to order notifications"
  default     = []

  validation {
    condition     = alltrue([for url in var.webhook_endpoints : startswith(url, "https://")])
    error_message = "All webhook endpoints must use HTTPS."
  }
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention for SNS delivery logs"
  default     = 7
}


