#!/bin/bash
set -euo pipefail

# Demo job that should FAIL due to denylist violation
echo "=== READY Demo Job - Denylist Violation ==="
echo "This job contains a denylisted command and should be blocked"

# This command is on the denylist and will be blocked by aos.ready.sh
sudo true

echo "This line should never execute"
