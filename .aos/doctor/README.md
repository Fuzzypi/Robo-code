# AOS Doctor

One command to check if your AOS install is healthy.

## Usage

```bash
./.aos/doctor/aos.doctor.sh
```

## What It Checks

### Core Files (Phase 1)
- `evlog.schema.json` exists
- `evlog.append.sh` exists and is executable

### Introspection Tools (Phase 2)
- `evlog.tail.sh` exists and is executable
- `evlog.summary.sh` exists and is executable
- `evlog.job.sh` exists and is executable

### Job Management (Phase 3)
- `job.start.sh` exists and is executable
- `job.end.sh` exists and is executable
- `job.show.sh` exists and is executable

### Run Wrapper (Phase 4)
- `run.sh` exists and is executable
- `run.job.sh` exists and is executable

### Timeline Report (Phase 5)
- `timeline.sh` exists and is executable
- `reports/` directory exists

### Workflow Guardrail (Phase 6)
- `WORKFLOW.md` exists

### Gitignore Rules
- `.aos/state/` is gitignored
- `.aos/reports/` is gitignored

### Evlog Write Test
- Attempts to write a test event
- Verifies write succeeded
- Cleans up test event (no permanent changes)

### Job Binding Status
- Reports active job if one exists
- Reports "no active job" if clean

### Subtree Sync Status
- Checks for uncommitted changes in subtree
- Verifies aos-core remote is configured

## Output Format

```
✅ = Pass (all good)
⚠️  = Warning (non-blocking, but should address)
❌ = Fail (needs attention)
```

Each failed check includes a suggested fix command.

## Example Output

```
╔════════════════════════════════════════╗
║         AOS Doctor Health Check        ║
╚════════════════════════════════════════╝

AOS Directory: /path/to/.aos
Repo Root: /path/to/repo

━━━ Core Files ━━━

✅ evlog.schema.json exists
✅ evlog.append.sh exists and executable

━━━ Summary ━━━

  ✅ Pass:    15
  ⚠️  Warn:    2
  ❌ Fail:    0
  ─────────────
  Total:     17 checks

Status: HEALTHY (with warnings)
```

## Behavior

- **Read-only**: Never modifies your files (except temporary evlog test, which is rolled back)
- **No enforcement**: Always exits 0, never blocks work
- **Helpful**: Provides fix commands for any issues found
- **Fast**: Runs all checks in under a second
