variable "prefix" {
  type        = string
  description = "Resource name prefix, e.g. order-processing-system-dev"
}

# ── Inputs from other modules ────────────
# Every ARN passed here becomes a precise resource
# constraint in the policy — no wildcards.

variable "orders_table_arn" {
  type        = string
  description = "DynamoDB orders table ARN — from module.dynamodb.table_arn"
}

variable "orders_queue_arn" {
  type        = string
  description = "SQS orders queue ARN — from module.sqs.queue_arn"
}

variable "orders_dlq_arn" {
  type        = string
  description = "SQS dead letter queue ARN — from module.sqs.dlq_arn"
}

variable "eventbridge_bus_arn" {
  type        = string
  description = "EventBridge custom bus ARN — from module.eventbridge.bus_arn"
}
