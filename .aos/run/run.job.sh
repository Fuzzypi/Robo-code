#!/bin/bash
# run.job.sh - Job-scoped command wrapper with automatic start/end
#
# BEHAVIOR:
#   - Calls job.start.sh to bind the job
#   - Calls run.sh to execute the command with logging
#   - Calls job.end.sh with appropriate result
#   - NEVER blocks: if any logging fails, command still runs
#   - Best-effort logging only
#
# USAGE:
#   ./run.job.sh <job_id> [agent_role] -- <command...>
#   ./run.job.sh AOS__EXAMPLE -- npm run verify
#   ./run.job.sh AOS__EXAMPLE builder -- npm run build
#
# The "--" separator is required to distinguish job args from command args.
# If agent_role is omitted, defaults to "builder".

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"
JOB_START="${AOS_DIR}/job/job.start.sh"
JOB_END="${AOS_DIR}/job/job.end.sh"
RUN_SH="${SCRIPT_DIR}/run.sh"

# Parse arguments - extract job_id, optional agent_role, then command after "--"
JOB_ID=""
AGENT_ROLE="builder"
COMMAND_ARGS=()
FOUND_SEPARATOR=false
ARG_INDEX=0

for arg in "$@"; do
    if [ "$FOUND_SEPARATOR" = true ]; then
        COMMAND_ARGS+=("$arg")
    elif [ "$arg" = "--" ]; then
        FOUND_SEPARATOR=true
    else
        if [ $ARG_INDEX -eq 0 ]; then
            JOB_ID="$arg"
        elif [ $ARG_INDEX -eq 1 ]; then
            AGENT_ROLE="$arg"
        fi
        ((ARG_INDEX++))
    fi
done

# Validate inputs
if [ -z "$JOB_ID" ]; then
    echo "Usage: ./run.job.sh <job_id> [agent_role] -- <command...>"
    echo "Example: ./run.job.sh AOS__EXAMPLE -- npm run verify"
    echo "         ./run.job.sh AOS__EXAMPLE builder -- npm run build"
    exit 1
fi

if [ ${#COMMAND_ARGS[@]} -eq 0 ]; then
    echo "Error: No command specified after '--'"
    echo "Usage: ./run.job.sh <job_id> [agent_role] -- <command...>"
    exit 1
fi

# Start job (best-effort - don't fail if this fails)
if [ -x "$JOB_START" ]; then
    "$JOB_START" "$JOB_ID" "$AGENT_ROLE" 2>/dev/null || true
fi

# Run the command
"$RUN_SH" -- "${COMMAND_ARGS[@]}"
EXIT_CODE=$?

# Determine result for job end
if [ $EXIT_CODE -eq 0 ]; then
    JOB_RESULT="success"
else
    JOB_RESULT="failure"
fi

# End job (best-effort - don't fail if this fails)
if [ -x "$JOB_END" ]; then
    "$JOB_END" "$JOB_RESULT" 2>/dev/null || true
fi

# Exit with the original command's exit code
exit $EXIT_CODE
