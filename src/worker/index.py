import json
import os
import random
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
events = boto3.client("events")

TABLE_NAME = os.environ["ORDERS_TABLE_NAME"]
EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]
EVENT_SOURCE = os.environ["EVENT_SOURCE"]


def handler(event, context):
    """
    SQS-triggered handler. Returns batchItemFailures so that only
    failed messages are retried / sent to the DLQ, not the whole batch.
    """
    failed = []

    for record in event["Records"]:
        message_id = record["messageId"]
        try:
            body = json.loads(record["body"])
            order_id = body["order_id"]
            _process_order(order_id)
        except Exception as exc:
            print(f"[worker] ERROR processing message {message_id}: {exc}")
            failed.append({"itemIdentifier": message_id})

    return {"batchItemFailures": failed}


def _process_order(order_id: str) -> None:
    table = dynamodb.Table(TABLE_NAME)
    now = datetime.now(timezone.utc).isoformat()

    # PENDING → PROCESSING
    # ConditionExpression prevents double-processing if a duplicate message arrives.
    try:
        table.update_item(
            Key={"order_id": order_id},
            UpdateExpression="SET #s = :processing, updated_at = :now",
            ConditionExpression="#s = :pending",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={
                ":processing": "PROCESSING",
                ":pending": "PENDING",
                ":now": now,
            },
        )
    except ClientError as exc:
        if exc.response["Error"]["Code"] == "ConditionalCheckFailedException":
            # Order was already picked up by another worker invocation — skip silently.
            print(f"[worker] Order {order_id} already past PENDING, skipping")
            return
        raise

    print(f"[worker] Processing order {order_id}")

    # Simulate: 80% COMPLETED, 20% FAILED
    success = random.random() < 0.8
    final_status = "COMPLETED" if success else "FAILED"
    now = datetime.now(timezone.utc).isoformat()

    # PROCESSING → COMPLETED | FAILED
    table.update_item(
        Key={"order_id": order_id},
        UpdateExpression="SET #s = :final_status, updated_at = :now",
        ConditionExpression="#s = :processing",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":final_status": final_status,
            ":processing": "PROCESSING",
            ":now": now,
        },
    )

    print(f"[worker] Order {order_id} → {final_status}")

    # Publish outcome to EventBridge
    detail_type = "order.completed" if success else "order.failed"
    events.put_events(
        Entries=[
            {
                "Source": EVENT_SOURCE,
                "DetailType": detail_type,
                "Detail": json.dumps(
                    {"order_id": order_id, "status": final_status, "timestamp": now}
                ),
                "EventBusName": EVENT_BUS_NAME,
            }
        ]
    )
