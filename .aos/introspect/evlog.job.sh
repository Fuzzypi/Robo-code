#!/bin/bash
# evlog.job.sh - Filter events by job ID
#
# BEHAVIOR:
#   - Reads from .aos/logs/evlog.ndjson (read-only)
#   - Filters events matching the specified job_id
#   - NEVER modifies the log file
#   - Fails gracefully if log doesn't exist
#
# USAGE:
#   ./evlog.job.sh <job_id>       # Show all events for job
#   ./evlog.job.sh <job_id> -r    # Show in raw JSON
#   ./evlog.job.sh -l             # List all unique job IDs
#   ./evlog.job.sh -h             # Show help
#
# EXAMPLES:
#   ./evlog.job.sh AOS__PHASE1_OBSERVABILITY
#   ./evlog.job.sh AOS__PHASE1_OBSERVABILITY -r
#   ./evlog.job.sh -l

set -e

# Determine log file location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVLOG_FILE="${SCRIPT_DIR}/../logs/evlog.ndjson"

# Defaults
JOB_ID=""
RAW=false
LIST_JOBS=false

# Parse arguments
show_help() {
    echo "evlog.job.sh - Filter events by job ID"
    echo ""
    echo "Usage: ./evlog.job.sh [OPTIONS] <job_id>"
    echo ""
    echo "Options:"
    echo "  -r       Output raw JSON instead of formatted text"
    echo "  -l       List all unique job IDs"
    echo "  -h       Show this help message"
    echo ""
    echo "Arguments:"
    echo "  job_id   The job ID to filter by (required unless -l)"
    echo ""
    echo "Examples:"
    echo "  ./evlog.job.sh AOS__PHASE1_OBSERVABILITY"
    echo "  ./evlog.job.sh AOS__PHASE1_OBSERVABILITY -r"
    echo "  ./evlog.job.sh -l"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--raw)
            RAW=true
            shift
            ;;
        -l|--list)
            LIST_JOBS=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            if [ -z "$JOB_ID" ]; then
                JOB_ID="$1"
            fi
            shift
            ;;
    esac
done

# Check if log file exists
if [ ! -f "$EVLOG_FILE" ]; then
    echo "No events found (evlog.ndjson does not exist)"
    exit 0
fi

# Check if log file is empty
if [ ! -s "$EVLOG_FILE" ]; then
    echo "No events found (evlog.ndjson is empty)"
    exit 0
fi

# List all job IDs
if [ "$LIST_JOBS" = true ]; then
    echo "=== Unique Job IDs ==="
    echo ""
    jq -r '.job_id' "$EVLOG_FILE" | sort | uniq -c | sort -rn | while read count job; do
        echo "  $job ($count events)"
    done
    exit 0
fi

# Require job_id for filtering
if [ -z "$JOB_ID" ]; then
    echo "Error: job_id is required"
    echo "Usage: ./evlog.job.sh <job_id>"
    echo "       ./evlog.job.sh -l  (to list all job IDs)"
    exit 1
fi

# Filter events by job_id
MATCHES=$(jq -c "select(.job_id == \"$JOB_ID\")" "$EVLOG_FILE")

if [ -z "$MATCHES" ]; then
    echo "No events found for job: $JOB_ID"
    exit 0
fi

# Output events
if [ "$RAW" = true ]; then
    echo "$MATCHES"
else
    echo "=== Events for Job: $JOB_ID ==="
    echo ""
    echo "$MATCHES" | while IFS= read -r line; do
        timestamp=$(echo "$line" | jq -r '.timestamp // "unknown"')
        agent=$(echo "$line" | jq -r '.agent_role // "unknown"')
        action=$(echo "$line" | jq -r '.action_type // "unknown"')
        desc=$(echo "$line" | jq -r '.description // "no description"')
        result=$(echo "$line" | jq -r '.result // "unknown"')
        artifacts=$(echo "$line" | jq -r '.artifacts // [] | join(", ")')

        # Format result with indicator
        case "$result" in
            success) result_icon="✓" ;;
            failure) result_icon="✗" ;;
            aborted) result_icon="⊘" ;;
            *) result_icon="?" ;;
        esac

        echo "[$timestamp] $result_icon"
        echo "  Agent: $agent | Action: $action"
        echo "  $desc"
        if [ -n "$artifacts" ] && [ "$artifacts" != "" ]; then
            echo "  Artifacts: $artifacts"
        fi
        echo ""
    done

    # Summary
    total=$(echo "$MATCHES" | wc -l | tr -d ' ')
    success=$(echo "$MATCHES" | jq -r 'select(.result == "success")' | grep -c "timestamp" || echo 0)
    failure=$(echo "$MATCHES" | jq -r 'select(.result == "failure")' | grep -c "timestamp" || echo 0)

    echo "--- Summary: $total events (✓ $success success, ✗ $failure failure) ---"
fi
