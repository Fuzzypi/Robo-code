#!/bin/bash
# run.sh - Command wrapper with automatic evlog capture
#
# BEHAVIOR:
#   - Reads job context from .aos/state/current_job.json (if available)
#   - Emits evlog entry BEFORE running command (result: "started")
#   - Executes the command
#   - Emits evlog entry AFTER running (result: "success" or "failure")
#   - Captures exit_code, duration_ms, cwd, command
#   - NEVER blocks: if logging fails, command still runs
#   - Best-effort logging only
#
# USAGE:
#   ./run.sh -- <command...>
#   ./run.sh -- ls -la
#   ./run.sh -- npm run build
#
# The "--" separator is required to distinguish wrapper args from command args.

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"
EVLOG_SCRIPT="${AOS_DIR}/logs/evlog.append.sh"
GUARD_SH="${AOS_DIR}/guard/aos.guard.sh"

# Parse arguments - find the "--" separator
COMMAND_ARGS=()
FOUND_SEPARATOR=false

for arg in "$@"; do
    if [ "$FOUND_SEPARATOR" = true ]; then
        COMMAND_ARGS+=("$arg")
    elif [ "$arg" = "--" ]; then
        FOUND_SEPARATOR=true
    fi
done

# If no separator found, treat all args as the command
if [ "$FOUND_SEPARATOR" = false ]; then
    COMMAND_ARGS=("$@")
fi

# Build command string for logging
COMMAND_STRING="${COMMAND_ARGS[*]}"

# Get current working directory
CWD="$(pwd)"

# Function to emit evlog entry (best-effort, never blocks)
emit_log() {
    local action_type="$1"
    local description="$2"
    local result="$3"
    local exit_code="$4"
    local duration_ms="$5"

    if [ -x "$EVLOG_SCRIPT" ]; then
        # Build extra fields as JSON suffix (hacky but works with current evlog.append.sh)
        # For now, we'll include command info in description since evlog.append.sh doesn't support extra fields yet
        local full_desc="$description"
        if [ -n "$exit_code" ]; then
            full_desc="$description [exit=$exit_code, ${duration_ms}ms]"
        fi

        # Use auto-fill for job context
        "$EVLOG_SCRIPT" - - - - "$action_type" "$full_desc" "$result" 2>/dev/null || true
    fi
}

# Check if we have a command to run
if [ ${#COMMAND_ARGS[@]} -eq 0 ]; then
    echo "Usage: ./run.sh -- <command...>"
    echo "Example: ./run.sh -- ls -la"
    exit 1
fi


# Run guard checks (soft enforcement - warnings only, never blocks)
if [ -x "$GUARD_SH" ]; then
    "$GUARD_SH" 2>/dev/null || true
fi

# Emit "started" log entry (best-effort)
emit_log "command" "Running: $COMMAND_STRING" "started" "" ""

# Record start time
START_TIME_MS=$(($(date +%s) * 1000 + $(date +%N 2>/dev/null | cut -c1-3 || echo 0)))
# Fallback for macOS which doesn't support %N
if [ "$START_TIME_MS" -lt 1000000000000 ]; then
    START_TIME_MS=$(($(date +%s) * 1000))
fi

# Execute the command
"${COMMAND_ARGS[@]}"
EXIT_CODE=$?

# Record end time and calculate duration
END_TIME_MS=$(($(date +%s) * 1000 + $(date +%N 2>/dev/null | cut -c1-3 || echo 0)))
if [ "$END_TIME_MS" -lt 1000000000000 ]; then
    END_TIME_MS=$(($(date +%s) * 1000))
fi
DURATION_MS=$((END_TIME_MS - START_TIME_MS))

# Determine result
if [ $EXIT_CODE -eq 0 ]; then
    RESULT="success"
else
    RESULT="failure"
fi

# Emit completion log entry (best-effort)
emit_log "command" "Completed: $COMMAND_STRING" "$RESULT" "$EXIT_CODE" "$DURATION_MS"

# Exit with the original command's exit code
exit $EXIT_CODE
