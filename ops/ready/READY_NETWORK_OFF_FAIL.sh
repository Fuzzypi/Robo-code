#!/bin/bash
set -euo pipefail

# Demo job that should FAIL due to network policy violation
echo "=== READY Demo Job - Network Policy Violation ==="
echo "This job attempts to use network while network policy is OFF"

# This will be blocked because network is OFF in metadata
curl -s http://localhost:3001/health

echo "This line should never execute"
