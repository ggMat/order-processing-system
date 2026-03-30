locals {
  prefix = "order-processing-system-${var.environment}"
}

module "sqs" {
  source = "../../modules/sqs"

  prefix                        = local.prefix
  visibility_timeout            = var.sqs_visibility_timeout
  message_retention_seconds     = var.sqs_message_retention_seconds
  max_receive_count             = var.sqs_max_receive_count
  dlq_message_retention_seconds = var.sqs_dlq_retention_seconds
  alarm_dlq_threshold           = var.sqs_alarm_dlq_threshold
}