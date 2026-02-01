#!/bin/bash
# job.end.sh - End the current job context for AOS
#
# BEHAVIOR:
#   - Reads .aos/state/current_job.json
#   - Emits job_end event to evlog with result
#   - Clears the current job state
#   - NEVER blocks execution (fails silently on error)
#   - Best-effort logging only
#
# USAGE:
#   ./job.end.sh <result>
#
# RESULTS:
#   success | failure | aborted
#
# EXAMPLE:
#   ./job.end.sh success

set -e

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"
STATE_DIR="${AOS_DIR}/state"
STATE_FILE="${STATE_DIR}/current_job.json"
EVLOG_SCRIPT="${AOS_DIR}/logs/evlog.append.sh"

# Parse arguments
RESULT="${1:-aborted}"

# Validate result
case "$RESULT" in
  success|failure|aborted) ;;
  *) RESULT="aborted" ;;
esac

# Read current job context (best-effort)
if [ -f "${STATE_FILE}" ]; then
  JOB_ID="$(grep -o '"job_id"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "UNKNOWN")"
  AGENT_ROLE="$(grep -o '"owner"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")"
  REPO="$(grep -o '"repo"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")"
  BRANCH="$(grep -o '"branch"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")"
  STARTED_AT="$(grep -o '"started_at"[[:space:]]*:[[:space:]]*"[^"]*"' "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")"
else
  JOB_ID="UNKNOWN"
  AGENT_ROLE="unknown"
  REPO="unknown"
  BRANCH="unknown"
  STARTED_AT="unknown"
fi

# Generate end timestamp
ENDED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Emit job_end event to evlog (if script exists)
if [ -x "${EVLOG_SCRIPT}" ]; then
  "${EVLOG_SCRIPT}" \
    "${JOB_ID}" \
    "${AGENT_ROLE}" \
    "${REPO}" \
    "${BRANCH}" \
    "job_end" \
    "Job ended: ${JOB_ID} (${RESULT})" \
    "${RESULT}" 2>/dev/null || true
fi

# Clear current job state
{
  rm -f "${STATE_FILE}"
} 2>/dev/null || true

# Print confirmation (human readable)
echo "Job ended: ${JOB_ID}"
echo "  Result: ${RESULT}"
echo "  Started: ${STARTED_AT}"
echo "  Ended: ${ENDED_AT}"

# Exit successfully regardless of outcome
exit 0
