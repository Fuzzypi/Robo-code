#!/bin/bash
set -euo pipefail

# Demo job that should PASS with network enabled
echo "=== READY Demo Job - Network ON ==="
echo "This job uses network with explicit network policy ON"

# Check if the CRM export server is running
HEALTH_RESPONSE=$(curl -s http://localhost:3001/health || echo "connection_failed")

if [[ "$HEALTH_RESPONSE" == *"healthy"* ]] || [[ "$HEALTH_RESPONSE" == *"ok"* ]]; then
  echo "✓ Health check PASSED: Server is running"
  echo "Response: $HEALTH_RESPONSE"
  exit 0
elif [[ "$HEALTH_RESPONSE" == "connection_failed" ]]; then
  echo "✗ Health check FAILED: Could not connect to server"
  echo "Note: Ensure CRM export server is running on port 3001"
  echo "Start with: cd crm-web && node server/crm-export-server.cjs"
  exit 1
else
  echo "✓ Health check completed with response: $HEALTH_RESPONSE"
  exit 0
fi
