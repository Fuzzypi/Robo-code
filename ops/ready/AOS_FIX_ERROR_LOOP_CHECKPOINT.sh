#!/usr/bin/env bash
set -euo pipefail

# Everything goes to runner-provided run dir
: "${AOS_RUN_DIR:?AOS_RUN_DIR must be set by aos.ready.sh}"

# Log helper
log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$AOS_RUN_DIR/transcript.log" >/dev/null; }

log "Starting AOS loop fix: ignore ops/runs + checkpoint commit"

# 1) Ensure .gitignore exists and contains ops/runs/
if [ ! -f .gitignore ]; then
  log "Creating .gitignore"
  touch .gitignore
fi

if ! grep -qx 'ops/runs/' .gitignore; then
  log "Adding ops/runs/ to .gitignore"
  printf "\n# AOS runtime artifacts\nops/runs/\n" >> .gitignore
else
  log "ops/runs/ already present in .gitignore"
fi

# 2) If ops/runs is tracked, untrack it but keep files on disk
if git ls-files --error-unmatch ops/runs >/dev/null 2>&1; then
  log "ops/runs is tracked — removing from index (keeping files)"
  git rm -r --cached ops/runs >> "$AOS_RUN_DIR/transcript.log" 2>&1
else
  log "ops/runs is not tracked (good)"
fi

# 3) Stage changes (gitignore + any current work you intend to checkpoint)
log "Staging changes"
git add .gitignore >> "$AOS_RUN_DIR/transcript.log" 2>&1

# Stage common AOS paths if present (safe; ignored paths won't stage)
for p in aos.ready.sh aos .continue; do
  if [ -e "$p" ]; then
    log "Staging $p"
    git add "$p" >> "$AOS_RUN_DIR/transcript.log" 2>&1 || true
  fi
done

# 4) Commit checkpoint (allow-empty to avoid stalling if everything already committed)
msg="AOS: checkpoint READY runner + ignore ops/runs artifacts"
log "Creating checkpoint commit: $msg"
git commit --allow-empty -m "$msg" >> "$AOS_RUN_DIR/transcript.log" 2>&1

# 5) Verify clean
log "Verifying repo clean"
git status --porcelain | tee "$AOS_RUN_DIR/final_status.txt" >> "$AOS_RUN_DIR/transcript.log"

if [ -n "$(cat "$AOS_RUN_DIR/final_status.txt")" ]; then
  log "FAIL: repo still dirty after checkpoint"
  exit 1
fi

log "PASS: repo clean and checkpoint created"
