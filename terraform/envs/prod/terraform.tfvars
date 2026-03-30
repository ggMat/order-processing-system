aws_region             = "eu-west-1"
environment            = "prod"

# Lambda
lambda_memory      = 128
log_retention_days = 90 

# SQS
sqs_visibility_timeout        = 300
sqs_message_retention_seconds = 345600
sqs_max_receive_count         = 5
sqs_dlq_retention_seconds     = 1209600
sqs_alarm_dlq_threshold       = 1
