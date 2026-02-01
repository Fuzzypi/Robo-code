#!/bin/bash
# aos.run.sh - Golden Path Runner for Agents
#
# BEHAVIOR:
#   - Starts a job
#   - Runs commands through the AOS wrapper
#   - Ends the job with appropriate status
#   - Generates a timeline report (best-effort)
#   - Prints summary with next steps
#
# USAGE:
#   ./aos.run.sh <job_id> -- <command...>
#   ./aos.run.sh <job_id> <role> -- <command...>
#
# EXAMPLES:
#   ./aos.run.sh JOB__BUILD -- npm run build
#   ./aos.run.sh JOB__TEST builder -- npm test
#   ./aos.run.sh JOB__VERIFY -- ./scripts/verify.sh
#
# EXIT CODE:
#   Returns the exit code of the wrapped command
#   (AOS operations are best-effort and don't affect exit code)

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"

# Scripts
JOB_START="${AOS_DIR}/job/job.start.sh"
JOB_END="${AOS_DIR}/job/job.end.sh"
RUN_SH="${AOS_DIR}/run/run.sh"
TIMELINE="${AOS_DIR}/report/timeline.sh"
EVLOG_JOB="${AOS_DIR}/introspect/evlog.job.sh"

# Parse arguments
show_help() {
    echo "aos.run.sh - Golden Path Runner for Agents"
    echo ""
    echo "Usage: ./aos.run.sh <job_id> [role] -- <command...>"
    echo ""
    echo "Arguments:"
    echo "  job_id     Unique identifier for this job (e.g., JOB__BUILD)"
    echo "  role       Optional agent role (default: builder)"
    echo "  --         Separator before the command"
    echo "  command    The command to run"
    echo ""
    echo "Examples:"
    echo "  ./aos.run.sh JOB__BUILD -- npm run build"
    echo "  ./aos.run.sh JOB__TEST builder -- npm test"
    echo "  ./aos.run.sh JOB__VERIFY ops -- ./scripts/verify.sh"
    echo ""
    echo "Behavior:"
    echo "  1. Starts job with job.start.sh"
    echo "  2. Runs command through run.sh (logged)"
    echo "  3. Ends job with job.end.sh (success/failure)"
    echo "  4. Generates timeline report (best-effort)"
    echo "  5. Prints summary and next steps"
    echo ""
    echo "Exit Code:"
    echo "  Returns the exit code of the wrapped command"
    exit 0
}

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
fi

# Require at least job_id and command
if [[ $# -lt 3 ]]; then
    echo "Error: Missing arguments"
    echo "Usage: ./aos.run.sh <job_id> -- <command...>"
    echo "       ./aos.run.sh -h for help"
    exit 1
fi

# Parse job_id
JOB_ID="$1"
shift

# Parse optional role (if next arg is not --)
AGENT_ROLE="builder"
if [[ "$1" != "--" ]]; then
    AGENT_ROLE="$1"
    shift
fi

# Expect --
if [[ "$1" != "--" ]]; then
    echo "Error: Missing '--' separator before command"
    echo "Usage: ./aos.run.sh <job_id> [role] -- <command...>"
    exit 1
fi
shift

# Remaining args are the command
if [[ $# -lt 1 ]]; then
    echo "Error: No command provided after '--'"
    exit 1
fi
COMMAND="$*"

# ═══════════════════════════════════════════════════════════════
# GOLDEN PATH EXECUTION
# ═══════════════════════════════════════════════════════════════

echo ""
echo "╔════════════════════════════════════════╗"
echo "║       AOS Golden Path Runner           ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Job ID:  $JOB_ID"
echo "Role:    $AGENT_ROLE"
echo "Command: $COMMAND"
echo ""

# Step 1: Start job
echo "━━━ Starting Job ━━━"
if [[ -x "$JOB_START" ]]; then
    "$JOB_START" "$JOB_ID" "$AGENT_ROLE" 2>/dev/null || true
else
    echo "Warning: job.start.sh not found or not executable"
fi
echo ""

# Step 2: Run command through wrapper
echo "━━━ Running Command ━━━"
CMD_EXIT_CODE=0
if [[ -x "$RUN_SH" ]]; then
    "$RUN_SH" -- $COMMAND
    CMD_EXIT_CODE=$?
else
    # Fallback: run directly if wrapper not available
    echo "Warning: run.sh not found, running command directly"
    eval "$COMMAND"
    CMD_EXIT_CODE=$?
fi
echo ""

# Determine result
if [[ $CMD_EXIT_CODE -eq 0 ]]; then
    JOB_RESULT="success"
else
    JOB_RESULT="failure"
fi

# Step 3: End job
echo "━━━ Ending Job ━━━"
if [[ -x "$JOB_END" ]]; then
    "$JOB_END" "$JOB_RESULT" 2>/dev/null || true
else
    echo "Warning: job.end.sh not found or not executable"
fi
echo ""

# Step 4: Generate timeline report (best-effort)
REPORT_PATH=""
echo "━━━ Generating Timeline Report ━━━"
if [[ -x "$TIMELINE" ]]; then
    # Capture timeline output to get report path
    TIMELINE_OUTPUT=$("$TIMELINE" "$JOB_ID" 2>&1) || true
    echo "$TIMELINE_OUTPUT"

    # Extract report path from output
    REPORT_PATH=$(echo "$TIMELINE_OUTPUT" | grep "Report:" | sed 's/.*Report: //')
else
    echo "Warning: timeline.sh not found, skipping report"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo "╔════════════════════════════════════════╗"
echo "║              Summary                   ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "  Job ID:      $JOB_ID"
echo "  Exit Code:   $CMD_EXIT_CODE"
echo "  Result:      $JOB_RESULT"

if [[ -n "$REPORT_PATH" ]]; then
    echo "  Report:      $REPORT_PATH"
fi

echo ""
echo "━━━ Next Steps ━━━"
echo ""
echo "  View job events:"
echo "    $EVLOG_JOB $JOB_ID"
echo ""

if [[ -n "$REPORT_PATH" ]]; then
    echo "  View timeline report:"
    echo "    cat $REPORT_PATH"
    echo ""
fi

if [[ $CMD_EXIT_CODE -ne 0 ]]; then
    echo "  ⚠️  Command failed with exit code $CMD_EXIT_CODE"
    echo "  Review the output above for errors."
    echo ""
fi

# Return the command's exit code
exit $CMD_EXIT_CODE
