# Order Processing System - AWS Serverless Portfolio Project

This repository demonstrates a production-grade, event-driven order processing pipeline on AWS using a fully serverless architecture. Infrastructure is managed with Terraform, application logic is written in Python, and the entire deployment lifecycle — from infrastructure provisioning to Lambda code updates — is automated via GitHub Actions with OIDC-based keyless authentication.

## Technology Stack

- **Application Runtime:** Python 3.12 (AWS Lambda)
- **API Layer:** AWS API Gateway (HTTP API v2)
- **Database:** AWS DynamoDB (on-demand, with Global Secondary Indexes)
- **Message Queue:** AWS SQS (Standard Queue + Dead Letter Queue)
- **Event Bus:** AWS EventBridge (Custom Event Bus)
- **Notifications:** AWS SNS (email and webhook subscriptions)
- **Infrastructure as Code:** Terraform (modular, multi-environment)
- **State Management:** S3 + DynamoDB locking (per environment)
- **CI/CD:** GitHub Actions (two independent pipelines)
- **Authentication:** AWS IAM + OIDC (keyless, no long-lived credentials)

## Architecture Overview

```
User / Test Client
        │
        ▼
POST /orders (JSON)
        │
        ▼
API Gateway (HTTP API v2)
        │  Lambda proxy integration
        ▼
lambda_create_order  ──────────────────┐
        │                              │
        │ PutItem (status=PENDING)     │ SendMessage
        ▼                              ▼
    DynamoDB                         SQS Queue
    (orders)                (visibility timeout: 60s dev / 300s prod)
                                       │
                                       ▼
                               lambda_worker
                                       │
                      ┌────────────────┼────────────────┐
                      │                │                │
                      ▼                ▼                ▼
              Read order         PENDING →         COMPLETED|FAILED
              from DynamoDB    PROCESSING          (UpdateItem)
                                                       │
                                                       ▼
                                               EventBridge (custom bus)
                                              ┌────────┴────────┐
                                              ▼                 ▼
                                       order.completed    order.failed
                                              │                 │
                                              └────────┬────────┘
                                                       ▼
                                                      SNS
                                              (email / webhook)
```

**Failure handling:** Messages that exceed the retry threshold (3× dev, 5× prod) are routed to the Dead Letter Queue (14-day retention) for inspection without blocking healthy messages in the batch (`ReportBatchItemFailures`).

**Event archival:** EventBridge archives all events in prod (90-day retention) for replay and audit. Disabled in dev to reduce cost.

---

## Core Components & Design Rationale

### 1. API Gateway (HTTP API v2)

- **Role:** Single entry point for order submission. Accepts `POST /orders` and rejects all other routes with 404.
- **Implementation:** HTTP API v2 is used over REST API for lower latency (~60 ms overhead vs ~200 ms), lower cost, and native Lambda proxy integration with payload format 2.0. CORS is pre-configured to accept `POST` and `OPTIONS` from any origin with `Content-Type` and `Authorization` headers.
- **Throttling:** Rate-limited per stage — 50 req/sec (burst 20) in dev, 500 req/sec (burst 200) in prod — protecting downstream Lambda from traffic spikes.
- **Logging:** Structured JSON access logs (requestId, sourceIp, status, latency, error) are written to a dedicated CloudWatch log group.

### 2. Lambda — `create_order` Function

- **Role:** Validates the incoming request, creates the order record, and queues it for processing.
- **Implementation:** Validates that `customer_id` is present and `items` is a non-empty list. Generates a UUID `order_id`, converts item prices to `Decimal` (required by DynamoDB's boto3 client), calculates the order total as `sum(price × quantity)`, writes the order to DynamoDB with `status=PENDING`, and sends the `order_id` to SQS. Returns HTTP 201 with the `order_id`.
- **Environment Variables:** `ORDERS_TABLE_NAME`, `ORDERS_QUEUE_URL`, `ENVIRONMENT`
- **IAM Permissions:** `dynamodb:PutItem` (orders table only), `sqs:SendMessage` and `sqs:GetQueueAttributes` (orders queue only).

### 3. Lambda — `worker` Function

- **Role:** Processes queued orders, persists state transitions to DynamoDB, and publishes outcome events.
- **Implementation:** Triggered by SQS (batch size: 5 dev / 10 prod, max concurrency: 2 to prevent DynamoDB hot-key contention). Uses a `ConditionExpression` on the DynamoDB update to guard against double-processing. State machine: `PENDING → PROCESSING → COMPLETED | FAILED`. Simulates an 80/20 success-to-failure ratio. Publishes `order.completed` or `order.failed` to the custom EventBridge bus. Returns `batchItemFailures` so that only the specific failing message is retried and eventually routed to the DLQ — the healthy messages in the same batch are not penalised.
- **Environment Variables:** `ORDERS_TABLE_NAME`, `EVENT_BUS_NAME`, `EVENT_SOURCE`, `ENVIRONMENT`
- **IAM Permissions:** `dynamodb:GetItem/UpdateItem`, `sqs:ReceiveMessage/DeleteMessage/GetQueueAttributes`, `eventbridge:PutEvents` — all scoped to specific resource ARNs.

### 4. DynamoDB (Orders Table)

- **Role:** Single source of truth for all order state.
- **Implementation:** On-demand billing (PAY_PER_REQUEST) — no capacity planning required. Two Global Secondary Indexes allow efficient queries beyond the primary key:
  - `status-created_at-index`: query all orders by status (e.g., all `PENDING` orders).
  - `customer_id-created_at-index`: query all orders for a specific customer, sorted by time.
- **Security:** Encryption at rest enabled (AWS-managed key). Point-in-time recovery (PITR) is off in dev and configurable for prod.

### 5. SQS (Queue + Dead Letter Queue)

- **Role:** Decouples order creation from order processing, providing backpressure, retry semantics, and failure isolation.
- **Implementation:** Main queue uses SSE encryption. Visibility timeout is set to 60 s in dev and 300 s in prod — longer than the Lambda timeout to prevent duplicate processing. Messages exceeding the `maxReceiveCount` threshold (3 dev / 5 prod) are automatically moved to the DLQ. The DLQ retains messages for 14 days, giving operators time to inspect and replay failures.
- **Benefit:** Because the worker uses `ReportBatchItemFailures`, a single bad message in a batch does not poison the entire batch.

### 6. EventBridge (Custom Event Bus)

- **Role:** Decouples the worker's outcome events from downstream notification logic.
- **Implementation:** A custom event bus (`order-processing-system-{env}-orders`) receives `order.completed` and `order.failed` events. Two rules filter by `DetailType` and forward matching events to the SNS topic. A dedicated IAM role grants EventBridge permission to publish to SNS. Event archival is enabled only in prod (90-day retention) to support audit trails and event replay without incurring unnecessary cost in dev.

### 7. SNS (Notifications)

- **Role:** Fan out order outcome events to external subscribers (email, webhooks).
- **Implementation:** A single SNS topic receives all order events. Email subscriptions require manual confirmation; HTTPS (webhook) subscriptions are auto-confirmed. The topic policy explicitly allows EventBridge to publish. AWS-managed encryption is enabled.

### 8. IAM (Least-Privilege Roles)

- **Role:** Enforce the principle of least privilege for every Lambda function.
- **Implementation:** Two separate execution roles are created — one per Lambda function. Each role grants only the specific actions needed on the specific resources used by that function. No wildcard resources, no shared roles. This limits the blast radius if a function is compromised.

---

## CI/CD Automation with GitHub Actions

The deployment process is split into two independent pipelines, following the principle of separating infrastructure and application deployments.

### 1. Infrastructure Pipeline (`deploy-infra.yaml`)

**Trigger:** Push to `main` or pull request with changes under `terraform/`.

**Purpose:** Manages the full lifecycle of AWS infrastructure using Terraform.

**Process:**
1. **plan-dev** (runs on every trigger — PR and push):
   - Authenticates to AWS via OIDC (no stored credentials).
   - `terraform init` with remote S3 backend.
   - `terraform validate` to catch syntax errors early.
   - `terraform plan -var-file=terraform.tfvars -out=tfplan` to preview changes.
2. **deploy-dev** (push to `main` only, after plan-dev succeeds):
   - `terraform apply -auto-approve` using the saved plan.
3. **deploy-prod** (push to `main` only, after deploy-dev, requires manual GitHub environment approval):
   - Same steps against the prod environment.

**Key Features:**
- **Path-filtered:** Only runs when Terraform files change, skipping unnecessary executions.
- **Keyless auth:** OIDC eliminates the need for long-lived AWS access keys in GitHub Secrets.
- **Environment gate:** Prod apply requires explicit manual approval from an authorised reviewer.
- **Remote state:** S3 backend with DynamoDB locking prevents concurrent applies and state corruption.

### 2. Lambda Deployment Pipeline (`deploy-lambdas.yaml`)

**Trigger:** Push to `main` or pull request with changes under `src/`.

**Purpose:** Packages and deploys updated Lambda function code without touching infrastructure.

**Process:**
1. **deploy-dev** (push to `main` only):
   - Authenticates to AWS via OIDC.
   - Packages each function: `zip -j create-order.zip src/create_order/index.py` (flat archive — no nested directories).
   - Deploys via `aws lambda update-function-code --zip-file fileb://...`.
   - Repeated for the worker function.
2. **deploy-prod** (after deploy-dev, requires manual GitHub environment approval):
   - Same zip-and-deploy steps against prod function names.

**Key Features:**
- **Path-filtered:** Only triggers when application source code changes.
- **Separation of concerns:** Infrastructure and code deployments are fully independent. A one-line Python fix does not require a Terraform plan.
- **Zero-dependency packaging:** `boto3` is provided by the Lambda runtime — no `requirements.txt` or build step needed.
- **Environment gate:** Prod deployment requires the same manual approval as infrastructure changes.

---

## Key Architectural Decisions

1. **Serverless over containers:** Lambda eliminates the need to provision, patch, and scale EC2 instances or ECS tasks. For an event-driven order processing workload with variable traffic, pay-per-invocation serverless is more cost-effective and operationally simpler than always-on containers.

2. **HTTP API v2 over REST API:** HTTP API v2 offers lower latency, lower cost, and a simpler integration model (payload format 2.0). REST API's additional features (usage plans, request validation, caching) are not required here.

3. **Generic Terraform Lambda module:** A single `lambda` module is instantiated twice with different variables. This avoids duplicating 100+ lines of Terraform and ensures both functions stay in sync on shared configuration (runtime, handler, tagging). The only behavioural difference is `sqs_trigger_enabled = true` on the worker.

4. **`ReportBatchItemFailures` on the SQS event source mapping:** Returning only the specific failing message IDs (rather than raising an exception for the whole batch) ensures that healthy messages are not re-processed. Failed messages accumulate individual receive counts and eventually drain to the DLQ without penalising the rest of the batch.

5. **OIDC for GitHub Actions authentication:** Using OIDC eliminates long-lived AWS access keys from GitHub Secrets entirely. The OIDC trust is scoped to a specific repository, preventing other repositories from assuming the role even if they share the same GitHub organisation.

6. **All ARNs flow via module outputs — no data sources:** Resource ARNs and names are passed between modules using `module.x.output` references. This makes the dependency graph explicit, avoids circular dependencies, and eliminates the risk of Terraform reading back a stale deployed resource.

7. **EventBridge archive enabled only in prod:** Archiving every event adds cost and storage. Dev is a throwaway environment where event replay is not needed. Prod archives all events for 90 days to support compliance, debugging, and replay if a downstream consumer fails.

8. **DynamoDB `ConditionExpression` on status update:** The worker guards its `PENDING → PROCESSING` transition with a condition that the current status is still `PENDING`. This prevents a second concurrent invocation (e.g., after a visibility-timeout reset) from double-processing the same order.

---

## Environment Differences (Dev vs Prod)

| Setting | Dev | Prod |
|---|---|---|
| SQS Visibility Timeout | 60 s | 300 s |
| SQS Max Receive Count | 3 | 5 |
| Lambda Worker Batch Size | 5 | 10 |
| Lambda Worker Max Concurrency | 2 | 2 |
| API Gateway Rate Limit | 50 req/s | 500 req/s |
| API Gateway Burst Limit | 20 | 200 |
| DynamoDB PITR | false | false |
| EventBridge Archive | disabled | enabled (90 days) |
| CloudWatch Log Retention | 7 days | 90 days |

---

## Monitoring and Maintenance

- **CloudWatch Logs:** Both Lambda functions and API Gateway write structured logs to dedicated log groups (`/aws/lambda/order-processing-system-{env}-{function}`, `/aws/apigateway/...`). Log retention is set explicitly to avoid the "never expire" default.
- **DLQ Inspection:** Failed messages in the DLQ can be inspected via the AWS Console or CLI. They retain the original message body and SQS metadata for root-cause analysis.
- **EventBridge Archive (Prod):** All events published to the custom bus are archived. Failed or missed events can be replayed from the archive directly to the bus without code changes.
- **CloudWatch Alarms:** Alarm resources are defined but commented out in the Terraform modules (Lambda errors/duration/throttles, SQS DLQ depth, API Gateway 4xx/5xx/throttles, SNS delivery failures). Uncomment and configure SNS alarm actions to enable automated alerting.

---

## One-Time Bootstrap

The bootstrap module (`terraform/bootstrap/`) must be run once from a developer laptop before the CI/CD pipelines can function. It creates:

- S3 state buckets for dev and prod (encrypted, versioned, public access blocked).
- DynamoDB lock tables for dev and prod.
- GitHub OIDC IAM role scoped to this repository.

```bash
cd terraform/bootstrap
terraform init
terraform apply
# Copy the output role_arn to the AWS_ROLE_ARN GitHub repository secret.
```

> **Important:** Bootstrap uses local state intentionally (it's a one-shot operation). Never commit `terraform.tfstate`.

---

## Local Development

**Infrastructure (run from the relevant environment directory):**

```bash
cd terraform/envs/dev      # or terraform/envs/prod
terraform init
terraform validate
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

**Lambda code (deploy manually after applying infrastructure):**

```bash
zip -j create-order.zip src/create_order/index.py
aws lambda update-function-code \
  --function-name order-processing-system-dev-create-order \
  --zip-file fileb://create-order.zip

zip -j worker.zip src/worker/index.py
aws lambda update-function-code \
  --function-name order-processing-system-dev-worker \
  --zip-file fileb://worker.zip
```

**Test the API:**

```bash
curl -X POST https://<api-id>.execute-api.eu-west-1.amazonaws.com/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "customer-123",
    "items": [
      {"product_id": "prod-a", "quantity": 2, "price": 29.99},
      {"product_id": "prod-b", "quantity": 1, "price": 9.49}
    ]
  }'
```

---

## Project Structure

```
order-processing-system/
├── src/
│   ├── create_order/
│   │   └── index.py              # POST /orders handler — validates, stores, queues
│   └── worker/
│       └── index.py              # SQS consumer — processes, updates state, publishes events
├── terraform/
│   ├── bootstrap/                # One-time setup: S3 buckets, DynamoDB locks, OIDC role
│   ├── envs/
│   │   ├── dev/                  # Dev root module (main.tf wires all modules)
│   │   └── prod/                 # Prod root module
│   └── modules/
│       ├── api-gateway/          # HTTP API v2 + Lambda proxy integration
│       ├── lambda/               # Generic Lambda module (instantiated twice)
│       ├── dynamodb/             # Orders table + two GSIs
│       ├── sqs/                  # Orders queue + DLQ
│       ├── eventbridge/          # Custom event bus + rules + optional archive
│       ├── sns/                  # Topic + email/webhook subscriptions
│       └── iam/                  # Per-Lambda execution roles (least privilege)
├── diagrams/
│   └── order-processing-architecture.svg
└── .github/workflows/
    ├── deploy-infra.yaml         # Terraform plan/apply pipeline (dev → prod)
    └── deploy-lambdas.yaml       # Lambda packaging and deployment pipeline
```
