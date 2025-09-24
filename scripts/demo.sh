#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for the demo script" >&2
  exit 1
fi

curl :80/api/catalog/products?sku=SKU123 | jq
curl ":80/api/promise?sku=SKU123&postalCode=D01%20X2Y3" | jq
curl -H "Content-Type: application/json" \
     -H "Idempotency-Key: demo-key-123" \
     -d '{
       "userId": 42,
       "items": [{"sku": "SKU123", "qty": 1}],
       "address": {"line1": "1 Capel St", "postalCode": "D01 X2Y3"},
       "paymentMethod": "CARD",
       "promise": {"sku": "SKU123", "postalCode": "D01 X2Y3", "method": "STANDARD"}
     }' \
     :80/api/orders | jq
