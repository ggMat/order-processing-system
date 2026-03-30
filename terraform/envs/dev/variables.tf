variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

# ── Lambda ──────────────────────────────
variable "lambda_memory" {
  type    = number
  default = 128
}

variable "log_retention_days" {
  type    = number
  default = 7
}

# ── SQS ─────────────────────────────────
variable "sqs_visibility_timeout" {
  type    = number
  default = 60
}

variable "sqs_message_retention_seconds" {
  type    = number
  default = 345600 # 4 days
}

variable "sqs_max_receive_count" {
  type    = number
  default = 3
}

variable "sqs_dlq_retention_seconds" {
  type    = number
  default = 1209600 # 14 days
}

variable "sqs_alarm_dlq_threshold" {
  type    = number
  default = 1
}
