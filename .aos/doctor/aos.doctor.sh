#!/bin/bash
# aos.doctor.sh - AOS Health Check
#
# BEHAVIOR:
#   - Checks AOS installation health (read-only)
#   - Reports status with clear PASS/WARN/FAIL indicators
#   - Suggests fix commands for issues found
#   - Never blocks work (no enforcement)
#   - Temporary evlog write test is rolled back
#
# USAGE:
#   ./aos.doctor.sh           # Run health check
#   ./aos.doctor.sh -h        # Show help
#
# OUTPUT:
#   Human-readable health report with ✅/⚠️/❌ indicators

set -e

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "unknown")"

# Colors (if terminal supports them)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    GREEN=''
    YELLOW=''
    RED=''
    BOLD=''
    NC=''
fi

# Counters
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# Helper functions
pass() {
    echo -e "${GREEN}✅${NC} $1"
    ((PASS_COUNT++)) || true
}

warn() {
    echo -e "${YELLOW}⚠️${NC}  $1"
    if [ -n "$2" ]; then
        echo -e "   ${YELLOW}Fix:${NC} $2"
    fi
    ((WARN_COUNT++)) || true
}

fail() {
    echo -e "${RED}❌${NC} $1"
    if [ -n "$2" ]; then
        echo -e "   ${RED}Fix:${NC} $2"
    fi
    ((FAIL_COUNT++)) || true
}

section() {
    echo ""
    echo -e "${BOLD}━━━ $1 ━━━${NC}"
    echo ""
}

# Parse arguments
show_help() {
    echo "aos.doctor.sh - AOS Health Check"
    echo ""
    echo "Usage: ./aos.doctor.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h       Show this help message"
    echo ""
    echo "Checks:"
    echo "  - Required directories and files exist"
    echo "  - Gitignore rules are in place"
    echo "  - Evlog is writable"
    echo "  - Job binding status"
    echo "  - Subtree sync status (heuristic)"
    echo ""
    echo "Output:"
    echo "  ✅ = Pass"
    echo "  ⚠️  = Warning (non-blocking)"
    echo "  ❌ = Fail (needs attention)"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        *)
            shift
            ;;
    esac
done

# Header
echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║         AOS Doctor Health Check        ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""
echo "AOS Directory: $AOS_DIR"
echo "Repo Root: $REPO_ROOT"

# ═══════════════════════════════════════════════════════════════
# CHECK 1: Required Files - Core
# ═══════════════════════════════════════════════════════════════
section "Core Files"

# Schema
if [ -f "${AOS_DIR}/logs/evlog.schema.json" ]; then
    pass "evlog.schema.json exists"
else
    fail "evlog.schema.json missing" "Phase 1 not installed"
fi

# Append script
if [ -f "${AOS_DIR}/logs/evlog.append.sh" ]; then
    if [ -x "${AOS_DIR}/logs/evlog.append.sh" ]; then
        pass "evlog.append.sh exists and executable"
    else
        warn "evlog.append.sh exists but not executable" "chmod +x ${AOS_DIR}/logs/evlog.append.sh"
    fi
else
    fail "evlog.append.sh missing" "Phase 1 not installed"
fi

# ═══════════════════════════════════════════════════════════════
# CHECK 2: Required Files - Introspection
# ═══════════════════════════════════════════════════════════════
section "Introspection Tools"

INTROSPECT_FILES=("evlog.tail.sh" "evlog.summary.sh" "evlog.job.sh")
for f in "${INTROSPECT_FILES[@]}"; do
    if [ -f "${AOS_DIR}/introspect/$f" ]; then
        if [ -x "${AOS_DIR}/introspect/$f" ]; then
            pass "$f exists and executable"
        else
            warn "$f exists but not executable" "chmod +x ${AOS_DIR}/introspect/$f"
        fi
    else
        fail "$f missing" "Phase 2 not installed"
    fi
done

# ═══════════════════════════════════════════════════════════════
# CHECK 3: Required Files - Job Management
# ═══════════════════════════════════════════════════════════════
section "Job Management"

JOB_FILES=("job.start.sh" "job.end.sh" "job.show.sh")
for f in "${JOB_FILES[@]}"; do
    if [ -f "${AOS_DIR}/job/$f" ]; then
        if [ -x "${AOS_DIR}/job/$f" ]; then
            pass "$f exists and executable"
        else
            warn "$f exists but not executable" "chmod +x ${AOS_DIR}/job/$f"
        fi
    else
        fail "$f missing" "Phase 3 not installed"
    fi
done

# ═══════════════════════════════════════════════════════════════
# CHECK 4: Required Files - Run Wrapper
# ═══════════════════════════════════════════════════════════════
section "Run Wrapper"

RUN_FILES=("run.sh" "run.job.sh")
for f in "${RUN_FILES[@]}"; do
    if [ -f "${AOS_DIR}/run/$f" ]; then
        if [ -x "${AOS_DIR}/run/$f" ]; then
            pass "$f exists and executable"
        else
            warn "$f exists but not executable" "chmod +x ${AOS_DIR}/run/$f"
        fi
    else
        fail "$f missing" "Phase 4 not installed"
    fi
done

# ═══════════════════════════════════════════════════════════════
# CHECK 5: Required Files - Timeline Report
# ═══════════════════════════════════════════════════════════════
section "Timeline Report"

if [ -f "${AOS_DIR}/report/timeline.sh" ]; then
    if [ -x "${AOS_DIR}/report/timeline.sh" ]; then
        pass "timeline.sh exists and executable"
    else
        warn "timeline.sh exists but not executable" "chmod +x ${AOS_DIR}/report/timeline.sh"
    fi
else
    fail "timeline.sh missing" "Phase 5 not installed"
fi

if [ -d "${AOS_DIR}/reports" ]; then
    pass "reports/ directory exists"
else
    warn "reports/ directory missing" "mkdir -p ${AOS_DIR}/reports"
fi

# ═══════════════════════════════════════════════════════════════
# CHECK 6: Workflow Guardrail
# ═══════════════════════════════════════════════════════════════
section "Workflow Guardrail"

if [ -f "${AOS_DIR}/WORKFLOW.md" ]; then
    pass "WORKFLOW.md exists"
else
    warn "WORKFLOW.md missing" "Phase 6 not installed (guardrail doc)"
fi

# ═══════════════════════════════════════════════════════════════
# CHECK 7: Gitignore Rules
# ═══════════════════════════════════════════════════════════════
section "Gitignore Rules"

# Find gitignore file (could be in AOS dir or repo root)
AOS_GITIGNORE="${AOS_DIR}/../.gitignore"
if [ ! -f "$AOS_GITIGNORE" ]; then
    AOS_GITIGNORE="${REPO_ROOT}/.gitignore"
fi

if [ -f "$AOS_GITIGNORE" ]; then
    # Check for state/ ignore
    if grep -q "\.aos/state" "$AOS_GITIGNORE" 2>/dev/null || grep -q "state/" "$AOS_GITIGNORE" 2>/dev/null; then
        pass ".aos/state/ is gitignored"
    else
        warn ".aos/state/ not gitignored" "Add '.aos/state/' to .gitignore"
    fi

    # Check for reports/ ignore
    if grep -q "\.aos/reports" "$AOS_GITIGNORE" 2>/dev/null || grep -q "reports/\*.md" "$AOS_GITIGNORE" 2>/dev/null; then
        pass ".aos/reports/ is gitignored"
    else
        warn ".aos/reports/*.md not gitignored" "Add '.aos/reports/*.md' to .gitignore"
    fi
else
    warn "No .gitignore found" "Create .gitignore with AOS runtime paths"
fi

# ═══════════════════════════════════════════════════════════════
# CHECK 8: Evlog Write Test
# ═══════════════════════════════════════════════════════════════
section "Evlog Write Test"

EVLOG_FILE="${AOS_DIR}/logs/evlog.ndjson"

if [ -f "$EVLOG_FILE" ]; then
    pass "evlog.ndjson exists"

    # Get line count before
    BEFORE_COUNT=$(wc -l < "$EVLOG_FILE" | tr -d ' ')

    # Try to write a test entry
    APPEND_SCRIPT="${AOS_DIR}/logs/evlog.append.sh"
    if [ -x "$APPEND_SCRIPT" ]; then
        # Write test event
        TEST_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        "$APPEND_SCRIPT" "DOCTOR_CHECK" "doctor" "test" "test" "report" "AOS doctor write test" "success" 2>/dev/null || true

        # Verify write
        AFTER_COUNT=$(wc -l < "$EVLOG_FILE" | tr -d ' ')

        if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
            pass "evlog is writable (test event appended)"

            # Clean up: remove the test entry
            # Use sed to remove the last line (our test entry)
            if [ "$(uname)" = "Darwin" ]; then
                # macOS sed requires backup extension
                sed -i '' '$d' "$EVLOG_FILE" 2>/dev/null || true
            else
                sed -i '$d' "$EVLOG_FILE" 2>/dev/null || true
            fi

            # Verify cleanup
            CLEANUP_COUNT=$(wc -l < "$EVLOG_FILE" | tr -d ' ')
            if [ "$CLEANUP_COUNT" -eq "$BEFORE_COUNT" ]; then
                pass "test event cleaned up (evlog unchanged)"
            else
                warn "test event cleanup failed" "Manually remove last line from evlog.ndjson"
            fi
        else
            warn "evlog write test inconclusive" "Check evlog.append.sh permissions"
        fi
    else
        warn "Cannot run write test" "evlog.append.sh not executable"
    fi
else
    warn "evlog.ndjson does not exist yet" "Will be created on first event"
fi

# ═══════════════════════════════════════════════════════════════
# CHECK 9: Job Binding Status
# ═══════════════════════════════════════════════════════════════
section "Job Binding Status"

STATE_FILE="${AOS_DIR}/state/current_job.json"

if [ -f "$STATE_FILE" ]; then
    JOB_ID=$(jq -r '.job_id // "UNKNOWN"' "$STATE_FILE" 2>/dev/null || echo "UNKNOWN")
    STARTED=$(jq -r '.started_at // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
    OWNER=$(jq -r '.owner // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")

    pass "Active job detected"
    echo "   Job ID: $JOB_ID"
    echo "   Started: $STARTED"
    echo "   Owner: $OWNER"
else
    pass "No active job (clean state)"
fi

# ═══════════════════════════════════════════════════════════════
# CHECK 10: Subtree Sync Status (Heuristic)
# ═══════════════════════════════════════════════════════════════
section "Subtree Sync Status"

# Check if we're in a subtree context (ops/aos pattern)
AOS_PARENT=$(dirname "$AOS_DIR")
AOS_GRANDPARENT=$(dirname "$AOS_PARENT")

if [ "$(basename "$AOS_PARENT")" = "aos" ] && [ "$(basename "$AOS_GRANDPARENT")" = "ops" ]; then
    # We're in an app repo subtree (ops/aos)
    SUBTREE_PATH="ops/aos"

    # Check for uncommitted changes in subtree
    if git -C "$REPO_ROOT" diff --quiet "$SUBTREE_PATH" 2>/dev/null; then
        if git -C "$REPO_ROOT" diff --cached --quiet "$SUBTREE_PATH" 2>/dev/null; then
            pass "Subtree is clean (no uncommitted changes)"
        else
            warn "Subtree has staged changes" "Commit or unstage changes in $SUBTREE_PATH"
        fi
    else
        warn "Subtree has uncommitted changes" "Review changes in $SUBTREE_PATH"
    fi

    # Check if aos-core remote exists
    if git -C "$REPO_ROOT" remote | grep -q "^aos-core$" 2>/dev/null; then
        pass "aos-core remote configured"

        # Heuristic: check if local subtree is ahead of remote
        # This is best-effort and may not always be accurate
        git -C "$REPO_ROOT" fetch aos-core main --quiet 2>/dev/null || true

        echo "   Hint: Run 'git subtree pull --prefix=ops/aos aos-core main --squash' to sync"
    else
        warn "aos-core remote not configured" "git remote add aos-core https://github.com/Fuzzypi/Robo-code.git"
    fi
else
    # We're in AOS core (Robo-code) directly
    pass "Running in AOS core repository"
fi

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}━━━ Summary ━━━${NC}"
echo ""

TOTAL=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))

echo -e "  ${GREEN}✅ Pass:${NC}    $PASS_COUNT"
echo -e "  ${YELLOW}⚠️  Warn:${NC}    $WARN_COUNT"
echo -e "  ${RED}❌ Fail:${NC}    $FAIL_COUNT"
echo "  ─────────────"
echo "  Total:     $TOTAL checks"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "${RED}${BOLD}Status: NEEDS ATTENTION${NC}"
    echo "Some required components are missing. See ❌ items above."
elif [ "$WARN_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}Status: HEALTHY (with warnings)${NC}"
    echo "AOS is functional but some improvements are suggested."
else
    echo -e "${GREEN}${BOLD}Status: HEALTHY${NC}"
    echo "All checks passed. AOS is ready to use."
fi

echo ""

# Exit with appropriate code (but never block)
exit 0
