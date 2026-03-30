aws_region  = "eu-west-1"
environment = "dev"

# Lambda
lambda_memory      = 128
lambda_log_retention_days = 7

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

