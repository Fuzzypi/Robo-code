#!/bin/bash
# aos.guard.sh - Soft enforcement guardrails (non-blocking)
#
# PHILOSOPHY:
#   - Detect bad states
#   - Warn loudly
#   - NEVER block execution
#   - NEVER exit non-zero
#   - NEVER mutate anything
#
# This script answers: "Are we about to do something sketchy?"
# It does NOT prevent you from doing it.
#
# USAGE:
#   ./aos.guard.sh [--quiet]
#
# OPTIONS:
#   --quiet    Only output if warnings are found
#
# EXIT CODE: Always 0 (soft enforcement)

# Intentionally do NOT use "set -e" to avoid non-zero exits.

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AOS_DIR="$(dirname "$SCRIPT_DIR")"
STATE_DIR="${AOS_DIR}/state"
LOGS_DIR="${AOS_DIR}/logs"
EVLOG_SCRIPT="${AOS_DIR}/logs/evlog.append.sh"

# Parse arguments
QUIET_MODE=false
for arg in "$@"; do
    case "$arg" in
        --quiet|-q)
            QUIET_MODE=true
            ;;
    esac
done

# Find repo root (walk up looking for .git)
find_repo_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo ""
    return 1
}

REPO_ROOT="$(find_repo_root)"

# Collect warnings
WARNINGS=()

# ============================================
# Check 1: Job not started but aos run invoked
# ============================================
check_job_context() {
    local current_job_file="${STATE_DIR}/current_job.json"

    if [ ! -f "$current_job_file" ]; then
        WARNINGS+=("Job not started")
        return
    fi
}

# ============================================
# Check 2: Dirty git working tree
# ============================================
check_git_dirty() {
    if [ -z "$REPO_ROOT" ]; then
        return
    fi

    cd "$REPO_ROOT" >/dev/null 2>&1 || return

    local dirty_count
    dirty_count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

    if [ "$dirty_count" -gt 0 ]; then
        WARNINGS+=("Working tree dirty (${dirty_count} files)")
    fi
}

# ============================================
# Check 3: Detached HEAD
# ============================================
check_detached_head() {
    if [ -z "$REPO_ROOT" ]; then
        return
    fi

    cd "$REPO_ROOT" >/dev/null 2>&1 || return

    if ! git symbolic-ref HEAD >/dev/null 2>&1; then
        local short_sha
        short_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        WARNINGS+=("Detached HEAD at ${short_sha}")
    fi
}

# ============================================
# Check 4: Subtree out of sync with Robo-code
# ============================================
check_subtree_sync() {
    if [ -z "$REPO_ROOT" ]; then
        return
    fi

    cd "$REPO_ROOT" >/dev/null 2>&1 || return

    local subtree_path="${REPO_ROOT}/ops/aos"
    if [ ! -d "$subtree_path" ]; then
        return
    fi

    if ! git remote get-url aos-core >/dev/null 2>&1; then
        WARNINGS+=("Subtree out of sync (missing aos-core remote)")
        return
    fi

    local subtree_commit
    subtree_commit=$(git subtree split --prefix=ops/aos HEAD 2>/dev/null || echo "")

    local remote_commit
    remote_commit=$(git rev-parse --verify refs/remotes/aos-core/main 2>/dev/null || echo "")

    if [ -n "$subtree_commit" ] && [ -n "$remote_commit" ] && [ "$subtree_commit" != "$remote_commit" ]; then
        WARNINGS+=("Subtree out of sync with aos-core/main")
    elif [ -z "$remote_commit" ]; then
        WARNINGS+=("Subtree out of sync (aos-core/main not available)")
    fi
}

# ============================================
# Check 5: Missing evlog
# ============================================
check_evlog_exists() {
    local evlog_file="${LOGS_DIR}/evlog.ndjson"

    if [ ! -f "$evlog_file" ]; then
        WARNINGS+=("Missing evlog.ndjson")
    fi
}

# ============================================
# Check 6: Missing proof directory for active job
# ============================================
check_proof_directory() {
    local current_job_file="${STATE_DIR}/current_job.json"

    if [ ! -f "$current_job_file" ]; then
        return
    fi

    local job_id
    job_id=$(grep -o '"job_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$current_job_file" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')

    if [ -z "$job_id" ]; then
        return
    fi

    if [ -n "$REPO_ROOT" ]; then
        local proof_dir="${REPO_ROOT}/reports/jobs/${job_id}"
        if [ ! -d "$proof_dir" ]; then
            WARNINGS+=("Missing proof directory for job ${job_id}")
        fi
    fi
}

# ============================================
# Run all checks
# ============================================
run_checks() {
    check_job_context
    check_git_dirty
    check_detached_head
    check_subtree_sync
    check_evlog_exists
    check_proof_directory
}

# ============================================
# Output warnings
# ============================================
output_warnings() {
    local warning_count=${#WARNINGS[@]}

    if [ $warning_count -eq 0 ]; then
        if [ "$QUIET_MODE" = false ]; then
            echo "AOS Guard: clean"
        fi
        return
    fi

    echo "⚠️  AOS GUARD WARNING"
    for warning in "${WARNINGS[@]}"; do
        echo "- ${warning}"
    done
}

# ============================================
# Emit to evlog (best-effort)
# ============================================
emit_guard_log() {
    local warning_count=${#WARNINGS[@]}
    local result="clean"
    local description="Guard check: no warnings"

    if [ $warning_count -gt 0 ]; then
        result="warnings"
        description="Guard check: ${warning_count} warning(s)"
    fi

    if [ -x "$EVLOG_SCRIPT" ]; then
        "$EVLOG_SCRIPT" - - - - "guard_check" "$description" "$result" 2>/dev/null || true
    fi
}

# ============================================
# Main
# ============================================
main() {
    run_checks
    output_warnings
    emit_guard_log
    exit 0
}

main
