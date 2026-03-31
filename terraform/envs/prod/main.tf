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

module "dynamodb" {
  source = "../../modules/dynamodb"

  prefix                 = local.prefix
  billing_mode           = var.dynamodb_billing_mode
  ttl_enabled            = var.dynamodb_ttl_enabled
  point_in_time_recovery = var.dynamodb_point_in_time_recovery
  log_retention_days     = var.dynamodb_log_retention_days
}

module "sns" {
  source = "../../modules/sns"

  prefix                         = local.prefix
  email_endpoints                = var.sns_email_endpoints
  log_retention_days             = var.sns_log_retention_days
}

module "eventbridge" {
  source = "../../modules/eventbridge"

  prefix                 = local.prefix
  sns_topic_arn          = module.sns.topic_arn
  order_event_source     = var.eventbridge_event_source
  log_retention_days     = var.eventbridge_log_retention_days
  enable_archive         = var.eventbridge_enable_archive
  archive_retention_days = var.eventbridge_archive_retention_days
}