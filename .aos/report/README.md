# AOS Timeline Report Generator

One command to explain everything that happened in a job.

## Purpose

When you feel lost about what happened during a job, run one command and instantly see:
- Job start/end times
- Every command run (with exit codes and durations)
- Referenced artifacts
- Failures and where they occurred

## Usage

```bash
# Generate report for a specific job
./.aos/report/timeline.sh AOS__PHASE4_TEST

# Generate report for current job (reads from current_job.json)
./.aos/report/timeline.sh

# Show help
./.aos/report/timeline.sh -h
```

## Output

Reports are generated as markdown files at:

```
.aos/reports/timeline_<job_id>_<YYYYMMDD_HHMMSS>.md
```

## Example Output

A generated report includes:

1. **Job Metadata** - Job ID, repo, branch, time range
2. **Summary** - Event counts, success/failure stats
3. **Chronological Events** - All events in time order
4. **Commands Executed** - Table with command, exit code, duration
5. **Artifacts Referenced** - Deduplicated list of all artifacts
6. **Failures** - Any non-success results for quick debugging

## Behavior

- **Read-only**: Never modifies the evlog or any source files
- **Graceful degradation**: Produces a "no data" report if evlog is missing
- **Always exits 0**: No enforcement, purely informational
- **Gitignored**: Generated reports are runtime artifacts, not committed

## Directory Structure

```
.aos/
├── report/
│   ├── README.md           # This file
│   └── timeline.sh         # Report generator script
└── reports/                # Output directory (gitignored)
    ├── .gitkeep
    └── timeline_*.md       # Generated reports
```

## Examples

### Generate report for Phase 4 test job

```bash
./.aos/report/timeline.sh AOS__PHASE4_TEST
```

Output:
```
Timeline report generated:
  Job ID: AOS__PHASE4_TEST
  Report: .aos/reports/timeline_AOS__PHASE4_TEST_20260201_120000.md
```

### Generate report for current/active job

```bash
./.aos/report/timeline.sh
```

If `current_job.json` exists, uses that job ID. Otherwise uses `UNKNOWN`.

### View the generated report

```bash
cat .aos/reports/timeline_AOS__PHASE4_TEST_*.md
```

Or open in any markdown viewer for formatted output.
