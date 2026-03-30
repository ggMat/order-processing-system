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
  default = false # Change to true in a real prod environment for data protection
}

variable "dynamodb_log_retention_days" {
  type    = number
  default = 90
}
