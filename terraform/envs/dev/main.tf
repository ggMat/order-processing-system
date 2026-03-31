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

module "iam" {
  source = "../../modules/iam"

  prefix              = local.prefix
  orders_table_arn    = module.dynamodb.table_arn
  orders_queue_arn    = module.sqs.queue_arn
  orders_dlq_arn      = module.sqs.dlq_arn
  eventbridge_bus_arn = module.eventbridge.bus_arn
}

module "lambda_create_order" {
  source = "../../modules/lambda"

  prefix        = local.prefix
  function_name = "create-order"
  role_arn      = module.iam.create_order_role_arn
  memory_size   = var.lambda_memory
  timeout       = var.lambda_create_order_timeout
  log_retention_days = var.lambda_log_retention_days

  environment_variables = {
    ORDERS_TABLE_NAME  = module.dynamodb.table_name
    ORDERS_QUEUE_URL   = module.sqs.queue_url
    ENVIRONMENT        = var.environment
  }
}

module "lambda_worker" {
  source = "../../modules/lambda"

  prefix        = local.prefix
  function_name = "worker"
  role_arn      = module.iam.worker_role_arn
  memory_size   = var.lambda_memory
  timeout       = var.lambda_worker_timeout
  log_retention_days = var.lambda_log_retention_days

  sqs_trigger_enabled = true
  sqs_queue_arn       = module.sqs.queue_arn
  sqs_batch_size      = var.lambda_worker_batch_size
  sqs_max_concurrency = var.lambda_worker_max_concurrency

  environment_variables = {
    ORDERS_TABLE_NAME   = module.dynamodb.table_name
    EVENT_BUS_NAME      = module.eventbridge.bus_name
    EVENT_SOURCE        = module.eventbridge.order_event_source
    ENVIRONMENT         = var.environment
  }
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  prefix                     = local.prefix
  environment                = var.environment
  create_order_invoke_arn    = module.lambda_create_order.invoke_arn
  create_order_function_name = module.lambda_create_order.function_name
  log_retention_days         = var.lambda_log_retention_days
  throttling_burst_limit     = var.apigw_throttling_burst_limit
  throttling_rate_limit      = var.apigw_throttling_rate_limit
}