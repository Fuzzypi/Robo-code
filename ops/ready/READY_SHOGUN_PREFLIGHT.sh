set -euo pipefail
git rev-parse --abbrev-ref HEAD > "$AOS_RUN_DIR/branch.txt"
git rev-parse HEAD > "$AOS_RUN_DIR/commit_hash.txt"
git status --porcelain > "$AOS_RUN_DIR/git_status.txt"

if [ -n "$(git status --porcelain)" ]; then
    echo "Repository is dirty; exiting with failure."
    exit 1
fi