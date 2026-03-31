aws_region  = "eu-west-1"
environment = "dev"

# Lambda
lambda_memory      = 128
lambda_log_retention_days = 7
lambda_create_order_timeout   = 10
lambda_worker_timeout         = 60
lambda_worker_batch_size      = 5
lambda_worker_max_concurrency = 2

# SQS
sqs_visibility_timeout        = 60
sqs_message_retention_seconds = 345600
sqs_max_receive_count         = 3
sqs_dlq_retention_seconds     = 1209600
sqs_alarm_dlq_threshold       = 1

# DynamoDB
dynamodb_billing_mode           = "PAY_PER_REQUEST"
dynamodb_ttl_enabled            = false
dynamodb_point_in_time_recovery = false
dynamodb_log_retention_days     = 7

# SNS 
sns_email_endpoints         = ["luigi.matera.dev@gmail.com"]
sns_log_retention_days      = 7

# EventBridge
eventbridge_event_source           = "order-processing"
eventbridge_log_retention_days     = 7
eventbridge_enable_archive         = false
eventbridge_archive_retention_days = 7

# API Gateway
apigw_throttling_burst_limit = 20
apigw_throttling_rate_limit  = 50
