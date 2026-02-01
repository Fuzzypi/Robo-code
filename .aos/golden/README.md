# AOS Golden Path Runner

One standard entrypoint for all agent work. Makes behavior boring and consistent.

## Usage

```bash
./.aos/golden/aos.run.sh <job_id> -- <command...>
./.aos/golden/aos.run.sh <job_id> <role> -- <command...>
```

## What It Does

1. **Starts a job** - Binds context with `job.start.sh`
2. **Runs the command** - Through `run.sh` wrapper (logged to evlog)
3. **Ends the job** - With success/failure via `job.end.sh`
4. **Generates report** - Timeline report (best-effort)
5. **Prints next steps** - Exact commands to run next

## Examples

### Run a build

```bash
./.aos/golden/aos.run.sh JOB__BUILD -- npm run build
```

### Run tests with a specific role

```bash
./.aos/golden/aos.run.sh JOB__TEST qa -- npm test
```

### Run a verification script

```bash
./.aos/golden/aos.run.sh JOB__VERIFY -- ./scripts/verify.sh
```

### List files (simple command)

```bash
./.aos/golden/aos.run.sh JOB__LIST -- ls -la
```

## Example Output

```
╔════════════════════════════════════════╗
║       AOS Golden Path Runner           ║
╚════════════════════════════════════════╝

Job ID:  JOB__BUILD
Role:    builder
Command: npm run build

━━━ Starting Job ━━━
Job started: JOB__BUILD
  Owner: builder
  Repo: my-app
  Branch: main
  Started: 2026-02-01T12:00:00Z

━━━ Running Command ━━━
[command output here]

━━━ Ending Job ━━━
Job ended: JOB__BUILD (success)

━━━ Generating Timeline Report ━━━
Timeline report generated:
  Job ID: JOB__BUILD
  Report: .aos/reports/timeline_JOB__BUILD_20260201_120005.md

╔════════════════════════════════════════╗
║              Summary                   ║
╚════════════════════════════════════════╝

  Job ID:      JOB__BUILD
  Exit Code:   0
  Result:      success
  Report:      .aos/reports/timeline_JOB__BUILD_20260201_120005.md

━━━ Next Steps ━━━

  View job events:
    .aos/introspect/evlog.job.sh JOB__BUILD

  View timeline report:
    cat .aos/reports/timeline_JOB__BUILD_20260201_120005.md
```

## Exit Code

The golden path runner returns the exit code of the wrapped command:
- Exit 0 = command succeeded
- Exit non-zero = command failed

AOS operations (job start/end, report generation) are best-effort and don't affect the exit code.

## Why Use This

- **Consistency**: Every job follows the same pattern
- **Observability**: All work is logged to evlog
- **Traceability**: Timeline reports capture what happened
- **Simplicity**: One command instead of multiple steps

## For Agents

When starting any significant work, use the golden path:

```bash
# Instead of:
./job.start.sh MY_JOB
npm run build
./job.end.sh success

# Use:
./.aos/golden/aos.run.sh MY_JOB -- npm run build
```

This ensures consistent logging, proper job lifecycle, and automatic reporting.
