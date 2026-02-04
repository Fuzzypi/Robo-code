#!/bin/bash
set -euo pipefail

# Denylist patterns (blocked commands/patterns)
DENYLIST_PATTERNS=(
  "sudo"
  "rm -rf /"
  "rm -rf /tmp/aos_ready_denylist_test"
  "mkfs"
  "dd if="
  ":(){ :|:& };:"
)

JOB_SCRIPT=$1
JOB_JSON="${JOB_SCRIPT%.sh}.json"
RUN_DIR="ops/runs/$(basename $JOB_SCRIPT .sh)/$(date +%Y%m%d%H%M%S)"

# Create run directory early for logging
mkdir -p "$RUN_DIR"

# Validate existence of script and JSON metadata
if [[ ! -f "$JOB_SCRIPT" ]] || [[ ! -f "$JOB_JSON" ]]; then
  echo "AOS_READY_METADATA_MISSING: Required job script or metadata missing."
  echo "  Expected: $JOB_SCRIPT and $JOB_JSON"
  echo "FAIL: Metadata validation failed. Run directory: $RUN_DIR"
  exit 1
fi

# Validate denylist
for pattern in "${DENYLIST_PATTERNS[@]}"; do
  if grep -qF "$pattern" "$JOB_SCRIPT"; then
    echo "AOS_READY_DENYLIST_BLOCK: Denylisted command detected: $pattern"
    echo "  Found in: $JOB_SCRIPT"
    echo "FAIL: Denylist violation. Run directory: $RUN_DIR"
    exit 1
  fi
done

# Validate network policy
NETWORK_POLICY=$(jq -r '.network' "$JOB_JSON")
if [[ "$NETWORK_POLICY" != "ON" ]] && grep -qE 'curl|wget|nc |netcat' "$JOB_SCRIPT"; then
  echo "AOS_READY_NETWORK_BLOCK: Network usage detected but policy set to OFF."
  echo "  Script: $JOB_SCRIPT"
  echo "  Network policy: $NETWORK_POLICY"
  echo "FAIL: Network policy violation. Run directory: $RUN_DIR"
  exit 1
fi

# Capture start time
START_TIME=$(date +%Y-%m-%dT%H:%M:%S)

# Execute the job script, logging output
set +e  # Don't exit on error from job script
{
  bash "$JOB_SCRIPT"
} &> "$RUN_DIR/transcript.log"
JOB_EXIT_CODE=$?
set -e

# Capture end time
END_TIME=$(date +%Y-%m-%dT%H:%M:%S)

# Capture git information
REPO_PATH=$(jq -r '.repo_paths[0]' "$JOB_JSON")
if [[ -d "$REPO_PATH" ]]; then
  (
    cd "$REPO_PATH"
    git status &> "$RUN_DIR/git_status.txt" || echo "git status failed" > "$RUN_DIR/git_status.txt"
    git diff --stat &> "$RUN_DIR/git_diff_stat.txt" || echo "git diff failed" > "$RUN_DIR/git_diff_stat.txt"
    git log -1 --stat &> "$RUN_DIR/git_log_1_stat.txt" || echo "git log failed" > "$RUN_DIR/git_log_1_stat.txt"
  )
else
  echo "Repository path not found" > "$RUN_DIR/git_status.txt"
  echo "Repository path not found" > "$RUN_DIR/git_diff_stat.txt"
  echo "Repository path not found" > "$RUN_DIR/git_log_1_stat.txt"
fi

# Write metadata
jq \
  --arg start_time "$START_TIME" \
  --arg end_time "$END_TIME" \
  --argjson exit_code "$JOB_EXIT_CODE" \
  '. + {start_time: $start_time, end_time: $end_time, exit_code: $exit_code}' "$JOB_JSON" \
  > "$RUN_DIR/meta.json"

# Output summary with clear PASS/FAIL
if [[ $JOB_EXIT_CODE -eq 0 ]]; then
  echo "PASS: Job completed successfully (exit code: 0)"
  echo "  Run directory: $RUN_DIR"
  echo "  Artifacts: transcript.log, meta.json, git_status.txt, git_diff_stat.txt, git_log_1_stat.txt"
  exit 0
else
  echo "FAIL: Job exited with error (exit code: $JOB_EXIT_CODE)"
  echo "  Run directory: $RUN_DIR"
  echo "  Check transcript.log for details"
  exit 1
fi
