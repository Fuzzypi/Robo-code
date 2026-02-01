#!/bin/bash
# evlog.append.sh - Append-only event logging for AOS
#
# BEHAVIOR:
#   - Appends a single JSON entry to .aos/logs/evlog.ndjson
#   - NEVER overwrites existing data
#   - NEVER blocks execution (fails silently on error)
#   - Best-effort logging only
#   - Auto-reads job context from .aos/state/current_job.json if job_id not provided
#
# USAGE (explicit):
#   ./evlog.append.sh <job_id> <agent_role> <repo> <branch> <action_type> <description> <result> [artifacts...]
#
# USAGE (auto job context):
#   ./evlog.append.sh - - - - <action_type> <description> <result> [artifacts...]
#   (Use "-" to auto-fill from current job state)
#
# EXAMPLE:
#   ./evlog.append.sh "AOS__PHASE1_OBSERVABILITY" "builder" "Robo-code" "main" "file_change" "Created evlog schema" "success" ".aos/logs/evlog.schema.json"
#   ./evlog.append.sh - - - - "file_change" "Modified file" "success"

set -e  # Exit on error (but we wrap everything to fail silently)

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"
STATE_FILE="${AOS_DIR}/state/current_job.json"
EVLOG_FILE="${SCRIPT_DIR}/evlog.ndjson"

# Function to read from job state file
read_job_field() {
  local field="$1"
  local default="$2"
  if [ -f "${STATE_FILE}" ]; then
    local value
    value="$(grep -o "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "${STATE_FILE}" 2>/dev/null | sed 's/.*: *"\([^"]*\)"/\1/' || echo "")"
    if [ -n "$value" ]; then
      echo "$value"
      return
    fi
  fi
  echo "$default"
}

# Parse arguments
RAW_JOB_ID="${1:-unknown}"
RAW_AGENT_ROLE="${2:-unknown}"
RAW_REPO="${3:-unknown}"
RAW_BRANCH="${4:-unknown}"
ACTION_TYPE="${5:-unknown}"
DESCRIPTION="${6:-no description}"
RESULT="${7:-unknown}"
shift 7 2>/dev/null || true

# Auto-fill from job state if "-" or empty
if [ "$RAW_JOB_ID" = "-" ] || [ "$RAW_JOB_ID" = "unknown" ] || [ -z "$RAW_JOB_ID" ]; then
  JOB_ID="$(read_job_field "job_id" "UNKNOWN")"
else
  JOB_ID="$RAW_JOB_ID"
fi

if [ "$RAW_AGENT_ROLE" = "-" ] || [ "$RAW_AGENT_ROLE" = "unknown" ] || [ -z "$RAW_AGENT_ROLE" ]; then
  AGENT_ROLE="$(read_job_field "owner" "unknown")"
else
  AGENT_ROLE="$RAW_AGENT_ROLE"
fi

if [ "$RAW_REPO" = "-" ] || [ "$RAW_REPO" = "unknown" ] || [ -z "$RAW_REPO" ]; then
  REPO="$(read_job_field "repo" "unknown")"
else
  REPO="$RAW_REPO"
fi

if [ "$RAW_BRANCH" = "-" ] || [ "$RAW_BRANCH" = "unknown" ] || [ -z "$RAW_BRANCH" ]; then
  BRANCH="$(read_job_field "branch" "unknown")"
else
  BRANCH="$RAW_BRANCH"
fi

# Build artifacts array
ARTIFACTS="[]"
if [ $# -gt 0 ]; then
  ARTIFACTS="["
  FIRST=true
  for artifact in "$@"; do
    if [ "$FIRST" = true ]; then
      ARTIFACTS="${ARTIFACTS}\"${artifact}\""
      FIRST=false
    else
      ARTIFACTS="${ARTIFACTS},\"${artifact}\""
    fi
  done
  ARTIFACTS="${ARTIFACTS}]"
fi

# Generate timestamp (ISO 8601)
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Build JSON entry (single line for NDJSON format)
JSON_ENTRY=$(cat <<ENTRY
{"timestamp":"${TIMESTAMP}","job_id":"${JOB_ID}","agent_role":"${AGENT_ROLE}","repo":"${REPO}","branch":"${BRANCH}","action_type":"${ACTION_TYPE}","description":"${DESCRIPTION}","artifacts":${ARTIFACTS},"result":"${RESULT}"}
ENTRY
)

# Append to log file (fail silently)
{
  echo "${JSON_ENTRY}" >> "${EVLOG_FILE}"
} 2>/dev/null || true

# Exit successfully regardless of write outcome (never block)
exit 0
