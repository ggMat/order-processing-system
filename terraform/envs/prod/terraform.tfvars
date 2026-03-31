aws_region             = "eu-west-1"
environment            = "prod"

# Lambda
lambda_memory      = 128
lambda_log_retention_days = 90
lambda_create_order_timeout   = 10
lambda_worker_timeout         = 300
lambda_worker_batch_size      = 5
lambda_worker_max_concurrency = 2 

# SQS
sqs_visibility_timeout        = 300
sqs_message_retention_seconds = 345600
sqs_max_receive_count         = 5
sqs_dlq_retention_seconds     = 1209600
sqs_alarm_dlq_threshold       = 1

# DynamoDB
dynamodb_billing_mode           = "PAY_PER_REQUEST"
dynamodb_ttl_enabled            = false
dynamodb_point_in_time_recovery = false # Change to true in a real prod environment for data protection
dynamodb_log_retention_days     = 90

# SNS 
sns_email_endpoints         = ["luigi.matera.dev@gmail.com"]
sns_log_retention_days      = 90

# EventBridge
eventbridge_event_source           = "order-processing"
eventbridge_log_retention_days     = 90
eventbridge_enable_archive         = true
eventbridge_archive_retention_days = 90