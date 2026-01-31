#!/bin/bash
# evlog.tail.sh - Show last N events from the event log
#
# BEHAVIOR:
#   - Reads from .aos/logs/evlog.ndjson (read-only)
#   - Displays last N events in human-readable format
#   - NEVER modifies the log file
#   - Fails gracefully if log doesn't exist
#
# USAGE:
#   ./evlog.tail.sh [N]       # Show last N events (default: 20)
#   ./evlog.tail.sh -r [N]    # Show last N events in raw JSON
#   ./evlog.tail.sh -h        # Show help
#
# EXAMPLES:
#   ./evlog.tail.sh           # Last 20 events, formatted
#   ./evlog.tail.sh 5         # Last 5 events, formatted
#   ./evlog.tail.sh -r 10     # Last 10 events, raw JSON

set -e

# Determine log file location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVLOG_FILE="${SCRIPT_DIR}/../logs/evlog.ndjson"

# Defaults
COUNT=20
RAW=false

# Parse arguments
show_help() {
    echo "evlog.tail.sh - Show last N events from the event log"
    echo ""
    echo "Usage: ./evlog.tail.sh [OPTIONS] [N]"
    echo ""
    echo "Options:"
    echo "  -r       Output raw JSON instead of formatted text"
    echo "  -h       Show this help message"
    echo ""
    echo "Arguments:"
    echo "  N        Number of events to show (default: 20)"
    echo ""
    echo "Examples:"
    echo "  ./evlog.tail.sh           # Last 20 events"
    echo "  ./evlog.tail.sh 5         # Last 5 events"
    echo "  ./evlog.tail.sh -r 10     # Last 10 in raw JSON"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--raw)
            RAW=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                COUNT="$1"
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

# Output events
if [ "$RAW" = true ]; then
    tail -n "$COUNT" "$EVLOG_FILE"
else
    echo "=== Last $COUNT Events ==="
    echo ""
    tail -n "$COUNT" "$EVLOG_FILE" | while IFS= read -r line; do
        timestamp=$(echo "$line" | jq -r '.timestamp // "unknown"')
        job_id=$(echo "$line" | jq -r '.job_id // "unknown"')
        agent=$(echo "$line" | jq -r '.agent_role // "unknown"')
        action=$(echo "$line" | jq -r '.action_type // "unknown"')
        desc=$(echo "$line" | jq -r '.description // "no description"')
        result=$(echo "$line" | jq -r '.result // "unknown"')

        # Format result with indicator
        case "$result" in
            success) result_icon="✓" ;;
            failure) result_icon="✗" ;;
            aborted) result_icon="⊘" ;;
            *) result_icon="?" ;;
        esac

        echo "[$timestamp] $result_icon $job_id"
        echo "  Agent: $agent | Action: $action"
        echo "  $desc"
        echo ""
    done
fi
