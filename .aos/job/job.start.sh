#!/bin/bash
# job.start.sh - Start and bind a job context for AOS
#
# BEHAVIOR:
#   - Creates/overwrites .aos/state/current_job.json
#   - Emits job_start event to evlog
#   - NEVER blocks execution (fails silently on error)
#   - Best-effort logging only
#
# USAGE:
#   ./job.start.sh <job_id> [agent_role]
#
# EXAMPLE:
#   ./job.start.sh AOS__PHASE3_JOB_BINDING builder

set -e

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"
STATE_DIR="${AOS_DIR}/state"
STATE_FILE="${STATE_DIR}/current_job.json"
EVLOG_SCRIPT="${AOS_DIR}/logs/evlog.append.sh"

# Parse arguments
JOB_ID="${1:-UNKNOWN}"
AGENT_ROLE="${2:-unknown}"

# Detect repo and branch (best-effort)
REPO="$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"

# Generate timestamp (ISO 8601)
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Ensure state directory exists
{
  mkdir -p "${STATE_DIR}"
} 2>/dev/null || true

# Write current job state
{
  cat > "${STATE_FILE}" << JOBSTATE
{
  "job_id": "${JOB_ID}",
  "started_at": "${TIMESTAMP}",
  "owner": "${AGENT_ROLE}",
  "repo": "${REPO}",
  "branch": "${BRANCH}"
}
JOBSTATE
} 2>/dev/null || true

# Emit job_start event to evlog (if script exists)
if [ -x "${EVLOG_SCRIPT}" ]; then
  "${EVLOG_SCRIPT}" \
    "${JOB_ID}" \
    "${AGENT_ROLE}" \
    "${REPO}" \
    "${BRANCH}" \
    "job_start" \
    "Job started: ${JOB_ID}" \
    "success" 2>/dev/null || true
fi

# Print confirmation (human readable)
echo "Job started: ${JOB_ID}"
echo "  Owner: ${AGENT_ROLE}"
echo "  Repo: ${REPO}"
echo "  Branch: ${BRANCH}"
echo "  Started: ${TIMESTAMP}"

# Exit successfully regardless of outcome
exit 0
