#!/bin/bash
# evlog.append.sh - Append-only event logging for AOS
#
# BEHAVIOR:
#   - Appends a single JSON entry to .aos/logs/evlog.ndjson
#   - NEVER overwrites existing data
#   - NEVER blocks execution (fails silently on error)
#   - Best-effort logging only
#
# USAGE:
#   ./evlog.append.sh <job_id> <agent_role> <repo> <branch> <action_type> <description> <result> [artifacts...]
#
# EXAMPLE:
#   ./evlog.append.sh "AOS__PHASE1_OBSERVABILITY" "builder" "Robo-code" "main" "file_change" "Created evlog schema" "success" ".aos/logs/evlog.schema.json"

set -e  # Exit on error (but we wrap everything to fail silently)

# Determine log file location (relative to script or explicit)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVLOG_FILE="${SCRIPT_DIR}/evlog.ndjson"

# Parse arguments
JOB_ID="${1:-unknown}"
AGENT_ROLE="${2:-unknown}"
REPO="${3:-unknown}"
BRANCH="${4:-unknown}"
ACTION_TYPE="${5:-unknown}"
DESCRIPTION="${6:-no description}"
RESULT="${7:-unknown}"
shift 7 2>/dev/null || true

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
