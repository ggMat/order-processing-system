variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

# ── Lambda ──────────────────────────────
variable "lambda_memory" {
  type    = number
  default = 128
}

variable "lambda_log_retention_days" {
  type    = number
  default = 90
}

variable "lambda_create_order_timeout" {
  type    = number
  default = 10
}

variable "lambda_worker_timeout" {
  type    = number
  default = 60
}

variable "lambda_worker_batch_size" {
  type    = number
  default = 5
}

variable "lambda_worker_max_concurrency" {
  type    = number
  default = 2
}
# ── SQS ─────────────────────────────────
variable "sqs_visibility_timeout" {
  type    = number
  default = 300
}

variable "sqs_message_retention_seconds" {
  type    = number
  default = 345600 # 4 days
}

variable "sqs_max_receive_count" {
  type    = number
  default = 5
}

variable "sqs_dlq_retention_seconds" {
  type    = number
  default = 1209600 # 14 days
}

variable "sqs_alarm_dlq_threshold" {
  type    = number
  default = 1
}

# ── DynamoDB ─────────────────────────────
variable "dynamodb_billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

variable "dynamodb_ttl_enabled" {
  type    = bool
  default = false 
}

variable "dynamodb_point_in_time_recovery" {
  type    = bool
  default = false
}

variable "dynamodb_log_retention_days" {
  type    = number
  default = 90
}

# ── SNS ──────────────────────────────────
variable "sns_email_endpoints" {
  type    = list(string)
  default = []
}

variable "sns_log_retention_days" {
  type    = number
  default = 90
}

# ── EventBridge ──────────────────────────
variable "eventbridge_event_source" {
  type    = string
  default = "order-processing"
}

variable "eventbridge_log_retention_days" {
  type    = number
  default = 90
}

variable "eventbridge_enable_archive" {
  type    = bool
  default = true # Enable archiving in prod for data durability
}

variable "eventbridge_archive_retention_days" {
  type    = number
  default = 90
}

# ── API Gateway ──────────────────────────
variable "apigw_throttling_burst_limit" {
  type    = number
  default = 200
}

variable "apigw_throttling_rate_limit" {
  type    = number
  default = 500
}
