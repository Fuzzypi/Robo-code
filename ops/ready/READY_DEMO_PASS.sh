#!/bin/bash
set -euo pipefail

# Demo job that should PASS
echo "=== READY Demo Job - PASS Case ==="
echo "Starting demo job execution..."

# Simple safe operations
echo "Current date: $(date)"
echo "Current directory: $(pwd)"
echo "Listing workspace root:"
ls -la /Users/fuzzypi/Robo-code | head -10

# Create a temporary test file
TEST_FILE="/tmp/aos_ready_demo_pass_$(date +%s).txt"
echo "Test content from READY_DEMO_PASS" > "$TEST_FILE"
echo "Created test file: $TEST_FILE"
cat "$TEST_FILE"

# Clean up
rm "$TEST_FILE"
echo "Cleaned up test file"

echo "=== Demo job completed successfully ==="
