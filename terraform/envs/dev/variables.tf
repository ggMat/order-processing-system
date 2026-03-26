variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "lambda_memory" {
  type    = number
  default = 128
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "sqs_visibility_timeout" {
  type    = number
  default = 60
}
