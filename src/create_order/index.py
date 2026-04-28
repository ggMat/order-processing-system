import json
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal

import boto3

dynamodb = boto3.resource("dynamodb")
sqs = boto3.client("sqs")

TABLE_NAME = os.environ["ORDERS_TABLE_NAME"]
QUEUE_URL = os.environ["ORDERS_QUEUE_URL"]


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "Invalid JSON body"})

    customer_id = body.get("customer_id")
    items = body.get("items")

    if not customer_id:
        return _response(400, {"error": "customer_id is required"})
    if not items or not isinstance(items, list) or len(items) == 0:
        return _response(400, {"error": "items must be a non-empty list"})

    items = [
        {**item, "price": Decimal(str(item.get("price", 0)))}
        for item in items
    ]

    order_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    total = sum(
        item["price"] * int(item.get("quantity", 1))
        for item in items
    )

    order = {
        "order_id": order_id,
        "customer_id": customer_id,
        "items": items,
        "total": total,
        "status": "PENDING",
        "created_at": now,
        "updated_at": now,
    }

    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item=order)

    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps({"order_id": order_id}),
    )

    print(f"[create-order] Created order {order_id} for customer {customer_id}")

    return _response(201, {"order_id": order_id, "status": "PENDING"})


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }