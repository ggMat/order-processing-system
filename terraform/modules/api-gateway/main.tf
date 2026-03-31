# ──────────────────────────────────────────
# HTTP API (API Gateway v2)
#
# We use HTTP API over REST API because:
# - lower latency (~60ms vs ~100ms)
# - lower cost (~$1/million vs ~$3.50/million requests)
# - simpler to configure for Lambda proxy integrations
#
# REST API is only needed if you require features like
# API keys, usage plans, request validation schemas,
# or WAF integration — none of which we need here.
# ──────────────────────────────────────────

resource "aws_apigatewayv2_api" "orders" {
  name          = "${var.prefix}-orders"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
}

# ──────────────────────────────────────────
# CloudWatch log group for access logs
#
# Captures every request: method, path, status,
# latency, and integration error. Essential for
# debugging failed requests and tracking usage.
# ──────────────────────────────────────────

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.prefix}-orders"
  retention_in_days = var.log_retention_days
}

# ──────────────────────────────────────────
# Stage — maps to the environment name
#
# auto_deploy = true means changes to routes and
# integrations are deployed automatically without
# a separate deployment step.
# ──────────────────────────────────────────

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.orders.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn

    # Structured JSON logging — makes logs queryable with
    # CloudWatch Insights and easy to parse in dashboards
    format = jsonencode({
      requestId      = "$context.requestId"
      sourceIp       = "$context.identity.sourceIp"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      latency        = "$context.integrationLatency"
      errorMessage   = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }
}

# ──────────────────────────────────────────
# Lambda integration
#
# AWS_PROXY means API Gateway passes the full request
# to Lambda and returns whatever Lambda returns —
# no transformation. The Lambda function is responsible
# for returning a proper HTTP response shape.
# ──────────────────────────────────────────

resource "aws_apigatewayv2_integration" "create_order" {
  api_id                 = aws_apigatewayv2_api.orders.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.create_order_invoke_arn
  payload_format_version = "2.0" # leaner event shape vs 1.0
}

# ──────────────────────────────────────────
# Route — POST /orders
#
# This is the only public endpoint. All other paths
# return 404 by default from API Gateway.
# ──────────────────────────────────────────

resource "aws_apigatewayv2_route" "create_order" {
  api_id    = aws_apigatewayv2_api.orders.id
  route_key = "POST /orders"
  target    = "integrations/${aws_apigatewayv2_integration.create_order.id}"
}

# ──────────────────────────────────────────
# Lambda permission
#
# API Gateway needs explicit permission to invoke Lambda.
# Without this resource, API Gateway gets a 403 from Lambda
# even though the integration is correctly configured.
# source_arn scopes the permission to this specific API
# and stage only — not any API Gateway in the account.
# ──────────────────────────────────────────

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.create_order_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.orders.execution_arn}/*/*"
}

# ──────────────────────────────────────────
# CloudWatch alarms
# ──────────────────────────────────────────

# Alert on 4xx errors — client errors worth monitoring
# to catch misconfigured requests or auth issues
resource "aws_cloudwatch_metric_alarm" "4xx_errors" {
  alarm_name          = "${var.prefix}-apigw-4xx-errors"
  alarm_description   = "API Gateway is returning elevated 4xx errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.orders.id
    Stage = aws_apigatewayv2_stage.default.name
  }
}

# Alert on 5xx errors — server/integration errors
# any 5xx in prod means something is broken
resource "aws_cloudwatch_metric_alarm" "5xx_errors" {
  alarm_name          = "${var.prefix}-apigw-5xx-errors"
  alarm_description   = "API Gateway is returning 5xx errors — Lambda integration may be failing"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.orders.id
    Stage = aws_apigatewayv2_stage.default.name
  }
}

# Alert on throttled requests
resource "aws_cloudwatch_metric_alarm" "throttled" {
  alarm_name          = "${var.prefix}-apigw-throttled"
  alarm_description   = "API Gateway is throttling requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = var.throttling_burst_limit * 0.8
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.orders.id
    Stage = aws_apigatewayv2_stage.default.name
  }
}
