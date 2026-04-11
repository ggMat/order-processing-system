# ──────────────────────────────────────────
# Placeholder deployment package
#
# Terraform requires a zip file to exist when creating
# a Lambda function. We use a minimal placeholder so
# the infrastructure can be applied before the real
# application code is written or deployed.
#
# The real code is deployed by updating the zip in CI/CD
# via aws lambda update-function-code, or by pointing
# the source_code_hash at a built artifact.
# ──────────────────────────────────────────

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder_${var.function_name}.zip"

  source {
    content  = <<-JS
      exports.handler = async (event) => {
        console.log('Placeholder handler — deploy real code via CI/CD');
        console.log(JSON.stringify(event));
        return { statusCode: 200, body: 'placeholder' };
      };
    JS
    filename = "index.js"
  }
}

# ──────────────────────────────────────────
# CloudWatch log group
#
# Created explicitly so we control retention.
# If Lambda creates it implicitly, it defaults
# to "never expire" — logs accumulate forever.
# ──────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.prefix}-${var.function_name}"
  retention_in_days = var.log_retention_days
}

# ──────────────────────────────────────────
# Lambda function
# ──────────────────────────────────────────

resource "aws_lambda_function" "this" {
  function_name = "${var.prefix}-${var.function_name}"
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  environment {
    variables = var.environment_variables
  }

  # Ensure log group exists before function is created
  # so the first invocation doesn't hit a missing log group
  depends_on = [aws_cloudwatch_log_group.lambda]
}

# ──────────────────────────────────────────
# SQS event source mapping (worker only)
#
# When sqs_trigger_enabled = true, Lambda polls
# the queue and invokes the function in batches.
# max_concurrency caps how many parallel invocations
# SQS can trigger — prevents a message spike from
# exhausting the Lambda concurrency pool.
# ──────────────────────────────────────────

resource "aws_lambda_event_source_mapping" "sqs" {
  count = var.sqs_trigger_enabled ? 1 : 0

  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = var.sqs_batch_size
  enabled          = true

  scaling_config {
    maximum_concurrency = var.sqs_max_concurrency
  }

  # Report partial batch failures — if 1 of 10 messages
  # fails, only that message goes to the DLQ.
  # Without this, the entire batch is retried on any failure.
  function_response_types = ["ReportBatchItemFailures"]
}

# ──────────────────────────────────────────
# CloudWatch alarms
# ──────────────────────────────────────────

# Alert on any Lambda errors
# resource "aws_cloudwatch_metric_alarm" "errors" {
#   alarm_name          = "${var.prefix}-${var.function_name}-errors"
#   alarm_description   = "Lambda ${var.function_name} is throwing errors"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "Errors"
#   namespace           = "AWS/Lambda"
#   period              = 60
#   statistic           = "Sum"
#   threshold           = 0
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#     FunctionName = aws_lambda_function.this.function_name
#   }
# }
#

# Alert when duration approaches the timeout limit (>80%)
# Early warning before Lambda starts timing out entirely

# resource "aws_cloudwatch_metric_alarm" "duration" {
#   alarm_name          = "${var.prefix}-${var.function_name}-high-duration"
#   alarm_description   = "Lambda ${var.function_name} duration is approaching timeout limit"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 3
#   metric_name         = "Duration"
#   namespace           = "AWS/Lambda"
#   period              = 60
#   statistic           = "Maximum"
#   threshold           = var.timeout * 1000 * 0.8 # 80% of timeout in milliseconds
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#     FunctionName = aws_lambda_function.this.function_name
#   }
# }
#

# Alert on throttles — means Lambda concurrency limit is being hit

# resource "aws_cloudwatch_metric_alarm" "throttles" {
#   alarm_name          = "${var.prefix}-${var.function_name}-throttles"
#   alarm_description   = "Lambda ${var.function_name} is being throttled"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "Throttles"
#   namespace           = "AWS/Lambda"
#   period              = 60
#   statistic           = "Sum"
#   threshold           = 0
#   treat_missing_data  = "notBreaching"
#
#   dimensions = {
#     FunctionName = aws_lambda_function.this.function_name
#   }
# }