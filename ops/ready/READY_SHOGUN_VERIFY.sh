#!/usr/bin/env bash
set -euo pipefail

# Verify AOS_RUN_DIR is set
if [ -z "${AOS_RUN_DIR:-}" ]; then
  echo "FAIL: AOS_RUN_DIR not set"
  exit 1
fi

echo "✓ AOS_RUN_DIR is set: $AOS_RUN_DIR"

# Verify transcript.log exists (it should since we're running)
if [ ! -f "$AOS_RUN_DIR/transcript.log" ]; then
  echo "FAIL: transcript.log not found at $AOS_RUN_DIR/transcript.log"
  exit 1
fi

echo "✓ transcript.log exists"

# Verify we can write to it
echo "Test write from job script" >> "$AOS_RUN_DIR/transcript.log"

echo "✓ Can write to transcript.log"
echo "PASS: All verification checks passed"
