#!/usr/bin/env bash
set -euo pipefail

# Verify AOS_RUN_DIR is set
: "${AOS_RUN_DIR:?AOS_RUN_DIR must be set}"

echo "Shogun-lite Checkpoint: Verifying clean state and creating checkpoint commit"

# Capture git status before
git status > "$AOS_RUN_DIR/git_status_before.txt" 2>&1

# Check if repo is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "FAIL: Repository has uncommitted changes. Cannot create checkpoint."
  git status --porcelain
  exit 1
fi

echo "✓ Repository is clean"

# Check for verify sentinel (optional - may not exist for first run)
SENTINEL_FILE="ops/.aos_state/shogun_last_verify_pass"
if [ -f "$SENTINEL_FILE" ]; then
  cp "$SENTINEL_FILE" "$AOS_RUN_DIR/verify_sentinel.txt"
  echo "✓ Verify sentinel found: $(cat "$SENTINEL_FILE")"
else
  echo "! No verify sentinel found (may be first run)" | tee "$AOS_RUN_DIR/verify_sentinel.txt"
fi

# Create checkpoint commit
git commit --allow-empty -m "AOS CHECKPOINT: Shogun-lite verified"

echo "✓ Checkpoint commit created"

# Capture git status after
git status > "$AOS_RUN_DIR/git_status_after.txt" 2>&1

echo "PASS: Checkpoint created successfully"
