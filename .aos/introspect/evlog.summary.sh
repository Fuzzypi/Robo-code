#!/bin/bash
# evlog.summary.sh - Show summary statistics of the event log
#
# BEHAVIOR:
#   - Reads from .aos/logs/evlog.ndjson (read-only)
#   - Displays counts by action_type, agent_role, and result
#   - NEVER modifies the log file
#   - Fails gracefully if log doesn't exist
#
# USAGE:
#   ./evlog.summary.sh           # Show full summary
#   ./evlog.summary.sh -j        # Output as JSON
#   ./evlog.summary.sh -h        # Show help
#
# EXAMPLES:
#   ./evlog.summary.sh           # Human-readable summary
#   ./evlog.summary.sh -j        # JSON output for programmatic use

set -e

# Determine log file location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVLOG_FILE="${SCRIPT_DIR}/../logs/evlog.ndjson"

# Defaults
JSON_OUTPUT=false

# Parse arguments
show_help() {
    echo "evlog.summary.sh - Show summary statistics of the event log"
    echo ""
    echo "Usage: ./evlog.summary.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -j       Output as JSON"
    echo "  -h       Show this help message"
    echo ""
    echo "Output includes:"
    echo "  - Total event count"
    echo "  - Breakdown by action_type"
    echo "  - Breakdown by agent_role"
    echo "  - Breakdown by result"
    echo "  - Time range (first and last event)"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -j|--json)
            JSON_OUTPUT=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            shift
            ;;
    esac
done

# Check if log file exists
if [ ! -f "$EVLOG_FILE" ]; then
    if [ "$JSON_OUTPUT" = true ]; then
        echo '{"error": "evlog.ndjson does not exist", "total": 0}'
    else
        echo "No events found (evlog.ndjson does not exist)"
    fi
    exit 0
fi

# Check if log file is empty
if [ ! -s "$EVLOG_FILE" ]; then
    if [ "$JSON_OUTPUT" = true ]; then
        echo '{"error": "evlog.ndjson is empty", "total": 0}'
    else
        echo "No events found (evlog.ndjson is empty)"
    fi
    exit 0
fi

# Compute statistics
TOTAL=$(wc -l < "$EVLOG_FILE" | tr -d ' ')
FIRST_TS=$(head -1 "$EVLOG_FILE" | jq -r '.timestamp // "unknown"')
LAST_TS=$(tail -1 "$EVLOG_FILE" | jq -r '.timestamp // "unknown"')

# JSON output
if [ "$JSON_OUTPUT" = true ]; then
    jq -s '{
        total: length,
        time_range: {
            first: (.[0].timestamp // null),
            last: (.[-1].timestamp // null)
        },
        by_action_type: (group_by(.action_type) | map({key: .[0].action_type, count: length}) | from_entries),
        by_agent_role: (group_by(.agent_role) | map({key: .[0].agent_role, count: length}) | from_entries),
        by_result: (group_by(.result) | map({key: .[0].result, count: length}) | from_entries),
        by_job: (group_by(.job_id) | map({key: .[0].job_id, count: length}) | from_entries)
    }' "$EVLOG_FILE"
    exit 0
fi

# Human-readable output
echo "╔════════════════════════════════════════╗"
echo "║       AOS Event Log Summary            ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Total Events: $TOTAL"
echo "Time Range:   $FIRST_TS"
echo "           → $LAST_TS"
echo ""

echo "┌─────────────────────────────────────────┐"
echo "│ By Action Type                          │"
echo "├─────────────────────────────────────────┤"
jq -r '.action_type' "$EVLOG_FILE" | sort | uniq -c | sort -rn | while read count action; do
    printf "│  %-20s %10s events │\n" "$action" "$count"
done
echo "└─────────────────────────────────────────┘"
echo ""

echo "┌─────────────────────────────────────────┐"
echo "│ By Agent Role                           │"
echo "├─────────────────────────────────────────┤"
jq -r '.agent_role' "$EVLOG_FILE" | sort | uniq -c | sort -rn | while read count role; do
    printf "│  %-20s %10s events │\n" "$role" "$count"
done
echo "└─────────────────────────────────────────┘"
echo ""

echo "┌─────────────────────────────────────────┐"
echo "│ By Result                               │"
echo "├─────────────────────────────────────────┤"
jq -r '.result' "$EVLOG_FILE" | sort | uniq -c | sort -rn | while read count result; do
    case "$result" in
        success) icon="✓" ;;
        failure) icon="✗" ;;
        aborted) icon="⊘" ;;
        *) icon="?" ;;
    esac
    printf "│  %s %-18s %10s events │\n" "$icon" "$result" "$count"
done
echo "└─────────────────────────────────────────┘"
echo ""

echo "┌─────────────────────────────────────────┐"
echo "│ By Job ID                               │"
echo "├─────────────────────────────────────────┤"
jq -r '.job_id' "$EVLOG_FILE" | sort | uniq -c | sort -rn | while read count job; do
    # Truncate long job names
    if [ ${#job} -gt 25 ]; then
        job="${job:0:22}..."
    fi
    printf "│  %-25s %6s events │\n" "$job" "$count"
done
echo "└─────────────────────────────────────────┘"
