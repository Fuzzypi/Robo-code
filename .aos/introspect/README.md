# AOS Introspection Commands

Read-only tools for inspecting the Agent Operating System event log.

## Guarantees

| Property | Guarantee |
|----------|-----------|
| **Read-only** | These scripts NEVER modify the event log |
| **No enforcement** | These scripts NEVER block, gate, or control agent behavior |
| **Best-effort** | If the log doesn't exist, scripts exit gracefully |
| **Human-first** | Default output is human-readable text |

---

## Commands

### `evlog.tail.sh` — Show Recent Events

Display the last N events from the event log.

```bash
# Last 20 events (default)
./evlog.tail.sh

# Last 5 events
./evlog.tail.sh 5

# Last 10 events in raw JSON
./evlog.tail.sh -r 10

# Help
./evlog.tail.sh -h
```

**Example output:**

```
=== Last 20 Events ===

[2026-01-31T22:54:08Z] ✓ AOS__PHASE1_OBSERVABILITY
  Agent: builder | Action: file_change
  Implemented Phase 1 observability - evlog schema, append script, and documentation
```

---

### `evlog.job.sh` — Filter by Job ID

Show all events for a specific job, or list all job IDs.

```bash
# All events for a job
./evlog.job.sh AOS__PHASE1_OBSERVABILITY

# Raw JSON output
./evlog.job.sh AOS__PHASE1_OBSERVABILITY -r

# List all unique job IDs
./evlog.job.sh -l

# Help
./evlog.job.sh -h
```

**Example output:**

```
=== Events for Job: AOS__PHASE1_OBSERVABILITY ===

[2026-01-31T22:54:08Z] ✓
  Agent: builder | Action: file_change
  Implemented Phase 1 observability - evlog schema, append script, and documentation
  Artifacts: .aos/logs/evlog.schema.json, .aos/logs/evlog.append.sh, .aos/logs/README.md

--- Summary: 1 events (✓ 1 success, ✗ 0 failure) ---
```

**List jobs output:**

```
=== Unique Job IDs ===

  AOS__PHASE1_OBSERVABILITY (1 events)
```

---

### `evlog.summary.sh` — Statistics Overview

Display aggregate statistics about the event log.

```bash
# Human-readable summary
./evlog.summary.sh

# JSON output (for programmatic use)
./evlog.summary.sh -j

# Help
./evlog.summary.sh -h
```

**Example output:**

```
╔════════════════════════════════════════╗
║       AOS Event Log Summary            ║
╚════════════════════════════════════════╝

Total Events: 1
Time Range:   2026-01-31T22:54:08Z
           → 2026-01-31T22:54:08Z

┌─────────────────────────────────────────┐
│ By Action Type                          │
├─────────────────────────────────────────┤
│  file_change                   1 events │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ By Agent Role                           │
├─────────────────────────────────────────┤
│  builder                       1 events │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ By Result                               │
├─────────────────────────────────────────┤
│  ✓ success                     1 events │
└─────────────────────────────────────────┘
```

---

## Use Cases

### "What happened on this job?"

```bash
./evlog.job.sh MY_JOB_ID
```

### "What's been happening recently?"

```bash
./evlog.tail.sh 50
```

### "How many failures have there been?"

```bash
./evlog.summary.sh | grep failure
```

### "Get all events as JSON for analysis"

```bash
./evlog.tail.sh -r 1000 > events.json
```

---

## Dependencies

These scripts require:

- `bash` (standard shell)
- `jq` (JSON processor)

Most Unix-like systems have these installed by default.

---

## Phase 2 Scope

This is **Phase 2 introspection only**. It provides:

- ✅ Read-only inspection of the event log
- ✅ Filtering by job ID
- ✅ Aggregate statistics

It does NOT provide:

- ❌ Write access to logs
- ❌ Enforcement or gating
- ❌ Real-time monitoring
- ❌ Alerting or notifications

Future phases may add monitoring and alerting, but introspection remains read-only.
