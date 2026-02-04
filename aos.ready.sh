#!/bin/bash
set -euo pipefail

# Helper: log to both stdout and transcript
log() {
  echo "$@" | tee -a "$RUN_DIR/transcript.log"
}

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
RUN_DIR="ops/runs/$(basename "$JOB_SCRIPT" .sh)/$(date +%Y%m%d%H%M%S)"

# Create run directory and initialize transcript immediately
mkdir -p "$RUN_DIR"
: > "$RUN_DIR/transcript.log"

# Export AOS_RUN_DIR for job scripts to use
export AOS_RUN_DIR="$RUN_DIR"

# Validate existence of script and JSON metadata
if [[ ! -f "$JOB_SCRIPT" ]] || [[ ! -f "$JOB_JSON" ]]; then
  log "AOS_READY_METADATA_MISSING: Required job script or metadata missing."
  log "  Expected script: $JOB_SCRIPT"
  log "  Expected metadata: $JOB_JSON"
  log "FAIL: Metadata validation failed. Run directory: $RUN_DIR"
  exit 1
fi

# Validate denylist
for pattern in "${DENYLIST_PATTERNS[@]}"; do
  if grep -qF "$pattern" "$JOB_SCRIPT"; then
    log "AOS_READY_DENYLIST_BLOCK: Denylisted command detected: $pattern"
    log "  Found in: $JOB_SCRIPT"
    log "FAIL: Denylist violation. Run directory: $RUN_DIR"
    exit 1
  fi
done

# Extract network policy using grep/sed (no jq dependency)
NETWORK_POLICY=$(grep -o '"network"[[:space:]]*:[[:space:]]*"[^"]*"' "$JOB_JSON" 2>/dev/null | sed 's/.*"\([^"]*\)".*/\1/' || echo "OFF")

# Validate network policy
if [[ "$NETWORK_POLICY" != "ON" ]] && grep -qE 'curl|wget|nc |netcat' "$JOB_SCRIPT"; then
  log "AOS_READY_NETWORK_BLOCK: Network usage detected but policy set to OFF."
  log "  Script: $JOB_SCRIPT"
  log "  Network policy: $NETWORK_POLICY"
  log "FAIL: Network policy violation. Run directory: $RUN_DIR"
  exit 1
fi

# Capture start time
START_TIME=$(date +%Y-%m-%dT%H:%M:%S)
echo "START_TIME=$START_TIME" >> "$RUN_DIR/transcript.log"

# Execute the job script, logging output
set +e  # Don't exit on error from job script
{
  bash "$JOB_SCRIPT"
} >> "$RUN_DIR/transcript.log" 2>&1
JOB_EXIT_CODE=$?
set -e

# Capture end time
END_TIME=$(date +%Y-%m-%dT%H:%M:%S)
echo "END_TIME=$END_TIME" >> "$RUN_DIR/transcript.log"
echo "EXIT_CODE=$JOB_EXIT_CODE" >> "$RUN_DIR/transcript.log"

# Extract repo root using grep/sed (no jq dependency), default to current directory
REPO_ROOT=$(grep -o '"repo_roots"[[:space:]]*:[[:space:]]*\[[[:space:]]*"[^"]*"' "$JOB_JSON" 2>/dev/null | sed 's/.*"\([^"]*\)".*/\1/' || echo ".")

# Capture git information from repo root
if [[ -d "$REPO_ROOT/.git" ]] || git -C "$REPO_ROOT" rev-parse --git-dir &>/dev/null; then
  (
    cd "$REPO_ROOT"
    git status &> "$RUN_DIR/git_status.txt" || echo "git status failed" > "$RUN_DIR/git_status.txt"
    git diff --stat &> "$RUN_DIR/git_diff_stat.txt" || echo "git diff failed" > "$RUN_DIR/git_diff_stat.txt"
    git log -1 --stat &> "$RUN_DIR/git_log_1_stat.txt" || echo "git log failed" > "$RUN_DIR/git_log_1_stat.txt"
  )
else
  echo "Not a git repository: $REPO_ROOT" > "$RUN_DIR/git_status.txt"
  echo "Not a git repository: $REPO_ROOT" > "$RUN_DIR/git_diff_stat.txt"
  echo "Not a git repository: $REPO_ROOT" > "$RUN_DIR/git_log_1_stat.txt"
fi

# Write metadata (use jq if available, otherwise create simple JSON)
if command -v jq &>/dev/null; then
  jq \
    --arg start_time "$START_TIME" \
    --arg end_time "$END_TIME" \
    --argjson exit_code "$JOB_EXIT_CODE" \
    '. + {start_time: $start_time, end_time: $end_time, exit_code: $exit_code}' "$JOB_JSON" \
    > "$RUN_DIR/meta.json"
else
  # Fallback: create minimal JSON without jq
  cat > "$RUN_DIR/meta.json" <<EOF
{
  "job_name": "$(basename "$JOB_SCRIPT" .sh)",
  "start_time": "$START_TIME",
  "end_time": "$END_TIME",
  "exit_code": $JOB_EXIT_CODE,
  "run_dir": "$RUN_DIR"
}
EOF
fi

# Output summary with clear PASS/FAIL
if [[ $JOB_EXIT_CODE -eq 0 ]]; then
  log "PASS: Job completed successfully (exit code: 0)"
  log "  Run directory: $RUN_DIR"
  log "  Artifacts: transcript.log, meta.json, git_status.txt, git_diff_stat.txt, git_log_1_stat.txt"
  exit 0
else
  log "FAIL: Job exited with error (exit code: $JOB_EXIT_CODE)"
  log "  Run directory: $RUN_DIR"
  log "  Check transcript.log for details"
  exit 1
fi
