#!/bin/bash
set -e

BASE_URL=${1:-"http://localhost:8080"}
MAX_RETRIES=5
RETRY_INTERVAL=15

echo "==> Starting smoke tests against: $BASE_URL"

for i in $(seq 1 $MAX_RETRIES); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --connect-timeout 10 \
    --max-time 30 \
    "${BASE_URL}/actuator/health")

  if [ "$HTTP_CODE" == "200" ]; then
    echo "✓ Health check passed (attempt $i) - HTTP $HTTP_CODE"
    break
  fi

  echo "✗ Attempt $i failed - HTTP $HTTP_CODE. Retrying in ${RETRY_INTERVAL}s..."
  sleep $RETRY_INTERVAL

  if [ $i -eq $MAX_RETRIES ]; then
    echo "SMOKE TEST FAILED after $MAX_RETRIES attempts"
    exit 1
  fi
done

RESPONSE=$(curl -sf "${BASE_URL}/api/v1/payments/ping")
STATUS=$(echo $RESPONSE | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

if [ "$STATUS" == "UP" ]; then
  echo "✓ API ping passed - status=$STATUS"
else
  echo "✗ API ping FAILED - response=$RESPONSE"
  exit 1
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  "${BASE_URL}/actuator/health/readiness")

if [ "$HTTP_CODE" == "200" ]; then
  echo "✓ Readiness passed - HTTP $HTTP_CODE"
else
  echo "✗ Readiness FAILED - HTTP $HTTP_CODE"
  exit 1
fi

echo "==> ALL SMOKE TESTS PASSED"
