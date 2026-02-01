#!/bin/bash
# job.new.sh - Job Scaffolder
#
# BEHAVIOR:
#   - Creates standard job artifact directories and templates
#   - Idempotent: will not overwrite existing files
#   - Emits job_scaffold event to evlog
#   - Prints next steps
#
# USAGE:
#   ./job.new.sh <job_id> [title...]
#
# EXAMPLES:
#   ./job.new.sh AOS__PHASE9_TEST
#   ./job.new.sh AOS__PHASE9_TEST "Phase 9 Test Job"
#   ./job.new.sh JOB__BUILD "Build and verify"

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Scripts
EVLOG_APPEND="${AOS_DIR}/logs/evlog.append.sh"
GOLDEN_PATH="${AOS_DIR}/golden/aos.run.sh"

# Parse arguments
show_help() {
    echo "job.new.sh - Job Scaffolder"
    echo ""
    echo "Usage: ./job.new.sh <job_id> [title...]"
    echo ""
    echo "Arguments:"
    echo "  job_id     Unique identifier for the job (e.g., AOS__PHASE9_TEST)"
    echo "  title      Optional human-readable title for the job"
    echo ""
    echo "Creates:"
    echo "  reports/jobs/<job_id>/proof.md  - Proof template"
    echo "  jobs/<job_id>.md                - Job stub (if jobs/ exists)"
    echo ""
    echo "Examples:"
    echo "  ./job.new.sh AOS__PHASE9_TEST"
    echo "  ./job.new.sh AOS__PHASE9_TEST \"Phase 9 Test Job\""
    echo "  ./job.new.sh JOB__BUILD \"Build and verify\""
    echo ""
    echo "Behavior:"
    echo "  - Idempotent: will not overwrite existing files"
    echo "  - Emits job_scaffold event to evlog"
    exit 0
}

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
fi

# Require job_id
if [[ -z "$1" ]]; then
    echo "Error: job_id is required"
    echo "Usage: ./job.new.sh <job_id> [title...]"
    exit 1
fi

JOB_ID="$1"
shift

# Remaining args are the title
if [[ $# -gt 0 ]]; then
    TITLE="$*"
else
    TITLE="$JOB_ID"
fi

# Auto-detect repo info
REPO_NAME="$(basename "$REPO_ROOT")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
DATE="$(date +"%Y-%m-%d")"

# Paths
REPORTS_DIR="${REPO_ROOT}/reports/jobs/${JOB_ID}"
PROOF_FILE="${REPORTS_DIR}/proof.md"
JOBS_DIR="${REPO_ROOT}/jobs"
JOB_STUB="${JOBS_DIR}/${JOB_ID}.md"

# Track created artifacts
CREATED_ARTIFACTS=()
SKIPPED_ARTIFACTS=()

# ═══════════════════════════════════════════════════════════════
# SCAFFOLDING
# ═══════════════════════════════════════════════════════════════

echo ""
echo "╔════════════════════════════════════════╗"
echo "║         AOS Job Scaffolder             ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Job ID:  $JOB_ID"
echo "Title:   $TITLE"
echo "Repo:    $REPO_NAME"
echo "Branch:  $BRANCH"
echo ""

# Step 1: Create reports directory
echo "━━━ Creating Directories ━━━"
if [[ ! -d "$REPORTS_DIR" ]]; then
    mkdir -p "$REPORTS_DIR"
    echo "✅ Created: reports/jobs/${JOB_ID}/"
    CREATED_ARTIFACTS+=("reports/jobs/${JOB_ID}/")
else
    echo "⏭️  Exists:  reports/jobs/${JOB_ID}/"
fi
echo ""

# Step 2: Create proof.md template
echo "━━━ Creating Proof Template ━━━"
if [[ ! -f "$PROOF_FILE" ]]; then
    cat > "$PROOF_FILE" << PROOF_TEMPLATE
# ${TITLE} — Proof Artifact

**Date:** ${DATE}
**Job ID:** ${JOB_ID}
**Status:** In Progress

---

## Summary

<!-- Brief description of what this job accomplishes -->

---

## Commands Run

\`\`\`bash
# Commands executed during this job
\`\`\`

---

## Outputs

<!-- Key outputs, logs, or results -->

---

## Files Changed

| Path | Change |
|------|--------|
| <!-- file path --> | <!-- description --> |

---

## Result

- [ ] Task completed successfully
- [ ] Tests pass (if applicable)
- [ ] No regressions introduced

---

*Proof artifact for ${JOB_ID}*
PROOF_TEMPLATE
    echo "✅ Created: reports/jobs/${JOB_ID}/proof.md"
    CREATED_ARTIFACTS+=("reports/jobs/${JOB_ID}/proof.md")
else
    echo "⏭️  Exists:  reports/jobs/${JOB_ID}/proof.md (not overwritten)"
    SKIPPED_ARTIFACTS+=("reports/jobs/${JOB_ID}/proof.md")
fi
echo ""

# Step 3: Create job stub if jobs/ directory exists
echo "━━━ Checking for jobs/ Directory ━━━"
if [[ -d "$JOBS_DIR" ]]; then
    if [[ ! -f "$JOB_STUB" ]]; then
        cat > "$JOB_STUB" << JOB_STUB_TEMPLATE
# ${TITLE}

**Job ID:** ${JOB_ID}
**Created:** ${DATE}
**Branch:** ${BRANCH}

## Objective

<!-- What this job aims to accomplish -->

## Scope

<!-- What's in scope for this job -->

## Proof

See: [proof.md](../reports/jobs/${JOB_ID}/proof.md)
JOB_STUB_TEMPLATE
        echo "✅ Created: jobs/${JOB_ID}.md"
        CREATED_ARTIFACTS+=("jobs/${JOB_ID}.md")
    else
        echo "⏭️  Exists:  jobs/${JOB_ID}.md (not overwritten)"
        SKIPPED_ARTIFACTS+=("jobs/${JOB_ID}.md")
    fi
else
    echo "ℹ️  No jobs/ directory found (skipping job stub)"
fi
echo ""

# Step 4: Emit evlog event
echo "━━━ Logging to Evlog ━━━"
if [[ -x "$EVLOG_APPEND" ]]; then
    # Build artifacts JSON array
    ARTIFACTS_JSON=""
    for artifact in "${CREATED_ARTIFACTS[@]}"; do
        if [[ -n "$ARTIFACTS_JSON" ]]; then
            ARTIFACTS_JSON="${ARTIFACTS_JSON},"
        fi
        ARTIFACTS_JSON="${ARTIFACTS_JSON}\"${artifact}\""
    done

    "$EVLOG_APPEND" \
        "$JOB_ID" \
        "builder" \
        "$REPO_NAME" \
        "$BRANCH" \
        "job_scaffold" \
        "Scaffolded job: ${JOB_ID}" \
        "success" \
        "${CREATED_ARTIFACTS[*]}" 2>/dev/null || true

    echo "✅ Emitted job_scaffold event to evlog"
else
    echo "⚠️  evlog.append.sh not found, skipping evlog"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo "╔════════════════════════════════════════╗"
echo "║              Summary                   ║"
echo "╚════════════════════════════════════════╝"
echo ""

if [[ ${#CREATED_ARTIFACTS[@]} -gt 0 ]]; then
    echo "Created:"
    for artifact in "${CREATED_ARTIFACTS[@]}"; do
        echo "  ✅ $artifact"
    done
    echo ""
fi

if [[ ${#SKIPPED_ARTIFACTS[@]} -gt 0 ]]; then
    echo "Skipped (already exist):"
    for artifact in "${SKIPPED_ARTIFACTS[@]}"; do
        echo "  ⏭️  $artifact"
    done
    echo ""
fi

echo "━━━ Next Steps ━━━"
echo ""
echo "  1. Edit the proof template:"
echo "     \$EDITOR ${PROOF_FILE}"
echo ""
echo "  2. Run your job through the golden path:"
echo "     ${GOLDEN_PATH} ${JOB_ID} -- <your-command>"
echo ""
echo "  3. Update proof.md with results"
echo ""
echo "  4. Commit when complete:"
echo "     git add reports/jobs/${JOB_ID}/"
echo "     git commit -m \"docs: add ${JOB_ID} proof artifact\""
echo ""

exit 0
