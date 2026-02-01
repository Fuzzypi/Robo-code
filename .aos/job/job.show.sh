#!/bin/bash
# job.show.sh - Display current job binding for AOS
#
# BEHAVIOR:
#   - Reads and displays .aos/state/current_job.json
#   - Human-readable output
#   - NEVER blocks execution
#
# USAGE:
#   ./job.show.sh
#
# EXAMPLE:
#   ./job.show.sh

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"
STATE_FILE="${AOS_DIR}/state/current_job.json"

# Check if job state exists
if [ ! -f "${STATE_FILE}" ]; then
  echo "No active job binding."
  echo "  State file: ${STATE_FILE} (not found)"
  exit 0
fi

# Read and display job context
echo "Current Job Binding:"
echo "---"

JOB_ID="$(grep -o '"job_id"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")"
STARTED_AT="$(grep -o '"started_at"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")"
OWNER="$(grep -o '"owner"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")"
REPO="$(grep -o '"repo"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")"
BRANCH="$(grep -o '"branch"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")"

echo "  Job ID:    ${JOB_ID}"
echo "  Owner:     ${OWNER}"
echo "  Repo:      ${REPO}"
echo "  Branch:    ${BRANCH}"
echo "  Started:   ${STARTED_AT}"
echo "---"
echo "  State file: ${STATE_FILE}"

exit 0
