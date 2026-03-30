variable "prefix" {
  type        = string
  description = "Resource name prefix, e.g. order-processing-system-dev"
}

variable "visibility_timeout" {
  type        = number
  description = "Seconds a message is hidden after being received by a consumer"
  default     = 60

  validation {
    condition     = var.visibility_timeout >= 0 && var.visibility_timeout <= 43200
    error_message = "visibility_timeout must be between 0 and 43200 seconds (12 hours)."
  }
}

variable "message_retention_seconds" {
  type        = number
  description = "How long SQS retains an unprocessed message (seconds)"
  default     = 345600 # 4 days

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds must be between 60 (1 min) and 1209600 (14 days)."
  }
}

variable "max_receive_count" {
  type        = number
  description = "How many times a message can be received before being sent to the DLQ"
  default     = 3

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count must be between 1 and 1000."
  }
}

variable "dlq_message_retention_seconds" {
  type        = number
  description = "How long the DLQ retains failed messages (seconds)"
  default     = 1209600 # 14 days — keep failed messages longer for inspection

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "dlq_message_retention_seconds must be between 60 and 1209600."
  }
}

variable "alarm_dlq_threshold" {
  type        = number
  description = "Number of messages in DLQ that triggers a CloudWatch alarm"
  default     = 1
}
