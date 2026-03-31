# ──────────────────────────────────────────
# Shared: Lambda basic execution policy
#
# Every Lambda needs this to write logs to CloudWatch.
# Rather than duplicating it, we attach this managed
# policy to both Lambda roles.
# ──────────────────────────────────────────

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ══════════════════════════════════════════
# create-order Lambda role
#
# Needs to:
#   - write logs (basic execution)
#   - put items in DynamoDB (store new order)
#   - send messages to SQS (trigger worker)
# ══════════════════════════════════════════

resource "aws_iam_role" "create_order" {
  name               = "${var.prefix}-create-order"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# CloudWatch Logs — scoped to this function's log group only
resource "aws_iam_role_policy" "create_order_logs" {
  name = "${var.prefix}-create-order-logs"
  role = aws_iam_role.create_order.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudWatchLogs"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.prefix}-create-order:*"
    }]
  })
}

# DynamoDB — PutItem only, scoped to the orders table
# create-order never reads or deletes — only writes new orders
resource "aws_iam_role_policy" "create_order_dynamodb" {
  name = "${var.prefix}-create-order-dynamodb"
  role = aws_iam_role.create_order.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowDynamoDBPutOrder"
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem"
      ]
      Resource = var.orders_table_arn
    }]
  })
}

# SQS — SendMessage only, scoped to the orders queue
# create-order sends but never receives or deletes
resource "aws_iam_role_policy" "create_order_sqs" {
  name = "${var.prefix}-create-order-sqs"
  role = aws_iam_role.create_order.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowSQSSendMessage"
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = var.orders_queue_arn
    }]
  })
}

# ══════════════════════════════════════════
# worker Lambda role
#
# Needs to:
#   - write logs (basic execution)
#   - read + update items in DynamoDB (status transitions)
#   - consume messages from SQS (trigger source)
#   - publish events to EventBridge (emit outcome)
# ══════════════════════════════════════════

resource "aws_iam_role" "worker" {
  name               = "${var.prefix}-worker"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# CloudWatch Logs — scoped to worker's log group
resource "aws_iam_role_policy" "worker_logs" {
  name = "${var.prefix}-worker-logs"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudWatchLogs"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.prefix}-worker:*"
    }]
  })
}

# DynamoDB — GetItem + UpdateItem only
# worker reads the current order then updates its status
# it never creates or deletes orders
resource "aws_iam_role_policy" "worker_dynamodb" {
  name = "${var.prefix}-worker-dynamodb"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowDynamoDBReadWrite"
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:UpdateItem"
      ]
      Resource = var.orders_table_arn
    }]
  })
}

# SQS — consume messages from the orders queue
# ReceiveMessage + DeleteMessage are the minimum needed
# for an SQS event source mapping to work
resource "aws_iam_role_policy" "worker_sqs" {
  name = "${var.prefix}-worker-sqs"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSConsume"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.orders_queue_arn
      },
      {
        # Worker needs to read DLQ attributes for health checks
        Sid    = "AllowDLQRead"
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes"
        ]
        Resource = var.orders_dlq_arn
      }
    ]
  })
}

# EventBridge — PutEvents scoped to our custom bus only
# worker publishes order.completed / order.failed events
resource "aws_iam_role_policy" "worker_eventbridge" {
  name = "${var.prefix}-worker-eventbridge"
  role = aws_iam_role.worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridgePutEvents"
      Effect = "Allow"
      Action = [
        "events:PutEvents"
      ]
      Resource = var.eventbridge_bus_arn
    }]
  })
}
