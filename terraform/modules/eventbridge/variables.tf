variable "prefix" {
  type        = string
  description = "Resource name prefix, e.g. order-processing-system-dev"
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS topic to route matched events to — from module.sns.topic_arn"
}

variable "order_event_source" {
  type        = string
  description = "Event source string set by the worker Lambda when publishing events"
  default     = "order-processing"
}

variable "log_retention_days" {
  type        = number
  description = "Retention period for the EventBridge archive log group"
  default     = 7
}

variable "enable_archive" {
  type        = bool
  description = "Archive all events on the bus — useful for replay and audit"
  default     = false
}

variable "archive_retention_days" {
  type        = number
  description = "How long to keep archived events (0 = indefinitely)"
  default     = 30
}
