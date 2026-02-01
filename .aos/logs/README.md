# AOS Event Log (Evlog) — Observability Layer

## What is Evlog?

Evlog is a **structured, append-only log** that records agent actions for observability.

Every significant action an agent takes — executing commands, modifying files, making decisions, or generating reports — can be recorded as a timestamped event.

### Design Principles

1. **Human-readable first, machine-parseable second**
2. **Append-only**: Events are never modified or deleted
3. **Best-effort**: Logging failures never block execution
4. **Read-only by default**: Logs are for observation, not control

---

## What Evlog is NOT

| Evlog is... | Evlog is NOT... |
|-------------|-----------------|
| Observability | Enforcement |
| Passive recording | Active gatekeeping |
| Historical record | Permission system |
| Debugging aid | Workflow controller |

**Critical**: Evlog does not:
- Block or gate any agent action
- Enforce policies or rules
- Modify agent behavior
- Require successful logging before proceeding

---

## Files in This Directory

| File | Purpose |
|------|---------|
| `evlog.schema.json` | JSON Schema defining event structure |
| `evlog.append.sh` | Bash script for appending events |
| `evlog.ndjson` | Newline-delimited JSON log file (created on first write) |
| `README.md` | This documentation |

---

## Event Schema

Each event contains:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | string | ISO 8601 timestamp (UTC) |
| `job_id` | string | Unique job/task identifier |
| `agent_role` | enum | `builder`, `reviewer`, `pm`, `qa`, `ops`, `human` |
| `repo` | string | Repository name |
| `branch` | string | Git branch |
| `action_type` | enum | `command`, `file_change`, `decision`, `report`, `job_start`, `job_end` |
| `description` | string | Human-readable summary |
| `artifacts` | array | Paths to created/modified files |
| `result` | enum | `success`, `failure`, `aborted` |

---

## How Agents Emit Logs

### Using the Shell Script (Explicit Parameters)

```bash
./evlog.append.sh \
  "JOB_ID" \
  "agent_role" \
  "repo_name" \
  "branch" \
  "action_type" \
  "Human-readable description" \
  "result" \
  [artifact1] [artifact2] ...
```

### Using Auto-Fill from Job Context

When a job is bound via `.aos/job/job.start.sh`, you can use `-` to auto-fill context:

```bash
./evlog.append.sh - - - - "action_type" "description" "result" [artifacts...]
```

The script will read `job_id`, `agent_role`, `repo`, and `branch` from `.aos/state/current_job.json`.

If no job is bound, it gracefully falls back to `job_id: "UNKNOWN"`.

### Examples

**Explicit (all parameters):**
```bash
./evlog.append.sh \
  "AOS__PHASE1_OBSERVABILITY" \
  "builder" \
  "Robo-code" \
  "main" \
  "file_change" \
  "Created evlog schema and append script" \
  "success" \
  ".aos/logs/evlog.schema.json" \
  ".aos/logs/evlog.append.sh"
```

**Auto-context (with job bound):**
```bash
./evlog.append.sh - - - - "file_change" "Modified config" "success" "config.json"
```

### Programmatic Emission (Future)

Agents using other languages can append directly to `evlog.ndjson`:

1. Construct a JSON object matching the schema
2. Serialize to a single line (no pretty-printing)
3. Append to the file with a newline
4. Handle write failures silently

---

## Job Binding Integration

As of Phase 3, evlog integrates with job binding (see `.aos/job/README.md`).

### Automatic Job Events

When using job scripts:

- `job.start.sh` emits `action_type: "job_start"`
- `job.end.sh` emits `action_type: "job_end"`

### Workflow Example

```bash
# Start job (emits job_start)
./.aos/job/job.start.sh AOS__PHASE3_JOB_BINDING builder

# Work with auto-context
./.aos/logs/evlog.append.sh - - - - "file_change" "did x" "success"

# End job (emits job_end)
./.aos/job/job.end.sh success
```

---

## How Humans Inspect Logs

### View Recent Events

```bash
tail -20 .aos/logs/evlog.ndjson
```

### Pretty-Print All Events

```bash
cat .aos/logs/evlog.ndjson | jq .
```

### Filter by Job

```bash
cat .aos/logs/evlog.ndjson | jq 'select(.job_id == "AOS__PHASE1_OBSERVABILITY")'
```

### Filter by Agent Role

```bash
cat .aos/logs/evlog.ndjson | jq 'select(.agent_role == "builder")'
```

### View Job Timeline

```bash
cat .aos/logs/evlog.ndjson | jq 'select(.action_type == "job_start" or .action_type == "job_end")'
```

### Count Events by Type

```bash
cat .aos/logs/evlog.ndjson | jq -s 'group_by(.action_type) | map({type: .[0].action_type, count: length})'
```

---

## Log File Location

The canonical log file is:

```
.aos/logs/evlog.ndjson
```

This file:
- Is created automatically on first write
- Uses NDJSON format (one JSON object per line)
- Should be committed to version control for auditability
- Can be .gitignored in repos where log volume is high

---

## Graceful Degradation

Evlog is designed to never block execution:

| Condition | Behavior |
|-----------|----------|
| Job state missing | Uses `job_id: "UNKNOWN"` |
| Write fails | Silently continues |
| Invalid parameters | Uses defaults |
| Directory missing | Attempts to create, fails silently |

---

## Related Documentation

- `.aos/job/README.md` — Job binding and lifecycle management
- `.aos/README.md` — AOS overview
