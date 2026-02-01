# AOS Job Binding — Runtime Context Management

## What is Job Binding?

Job binding associates all agent actions with a **current job context**. This enables:

1. **Automatic evlog population** — logs include `job_id`, `repo`, `branch` without explicit parameters
2. **Timeline reconstruction** — trace all actions back to a specific job
3. **Clean job boundaries** — clear start and end for every task

---

## Design Principles

1. **Best-effort, never blocking** — job binding failures do not stop execution
2. **Automatic context** — evlog scripts auto-read from job state
3. **Graceful degradation** — missing job context uses `job_id: "UNKNOWN"`
4. **Human-readable output** — scripts print friendly confirmation messages

---

## Files in This Directory

| File | Purpose |
|------|---------|
| `job.start.sh` | Start a job and create binding |
| `job.end.sh` | End a job and clear binding |
| `job.show.sh` | Display current job binding |
| `README.md` | This documentation |

---

## Runtime State

Job state is stored in:

```
.aos/state/current_job.json
```

**Important:** This file is gitignored and never committed.

### State Format

```json
{
  "job_id": "AOS__PHASE3_JOB_BINDING",
  "started_at": "2026-01-31T20:00:00Z",
  "owner": "builder",
  "repo": "Robo-code",
  "branch": "main"
}
```

---

## Usage

### Starting a Job

```bash
./.aos/job/job.start.sh <job_id> [agent_role]
```

**Example:**
```bash
./.aos/job/job.start.sh AOS__PHASE3_JOB_BINDING builder
```

**Output:**
```
Job started: AOS__PHASE3_JOB_BINDING
  Owner: builder
  Repo: Robo-code
  Branch: main
  Started: 2026-01-31T20:00:00Z
```

**Effects:**
- Creates/overwrites `.aos/state/current_job.json`
- Emits `job_start` event to evlog

---

### Checking Current Job

```bash
./.aos/job/job.show.sh
```

**Output (with active job):**
```
Current Job Binding:
---
  Job ID:    AOS__PHASE3_JOB_BINDING
  Owner:     builder
  Repo:      Robo-code
  Branch:    main
  Started:   2026-01-31T20:00:00Z
---
  State file: /path/to/.aos/state/current_job.json
```

**Output (no active job):**
```
No active job binding.
  State file: /path/to/.aos/state/current_job.json (not found)
```

---

### Emitting Events (Auto-Context)

Once a job is started, evlog auto-fills context:

```bash
# Explicit (all parameters)
./.aos/logs/evlog.append.sh "JOB_ID" "builder" "repo" "branch" "file_change" "did x" "success"

# Auto-context (use "-" for auto-fill)
./.aos/logs/evlog.append.sh - - - - "file_change" "did x" "success"
```

Both produce equivalent log entries when a job is active.

---

### Ending a Job

```bash
./.aos/job/job.end.sh <result>
```

**Results:** `success` | `failure` | `aborted`

**Example:**
```bash
./.aos/job/job.end.sh success
```

**Output:**
```
Job ended: AOS__PHASE3_JOB_BINDING
  Result: success
  Started: 2026-01-31T20:00:00Z
  Ended: 2026-01-31T20:15:00Z
```

**Effects:**
- Emits `job_end` event to evlog with result
- Removes `.aos/state/current_job.json`

---

## Complete Workflow Example

```bash
# 1. Start job
./.aos/job/job.start.sh AOS__PHASE3_JOB_BINDING builder

# 2. Do work (evlog auto-fills job context)
./.aos/logs/evlog.append.sh - - - - "file_change" "Created job scripts" "success" ".aos/job/job.start.sh"

# 3. Check current binding
./.aos/job/job.show.sh

# 4. End job
./.aos/job/job.end.sh success
```

**Resulting evlog entries:**
```json
{"timestamp":"...","job_id":"AOS__PHASE3_JOB_BINDING","agent_role":"builder","repo":"Robo-code","branch":"main","action_type":"job_start","description":"Job started: AOS__PHASE3_JOB_BINDING","artifacts":[],"result":"success"}
{"timestamp":"...","job_id":"AOS__PHASE3_JOB_BINDING","agent_role":"builder","repo":"Robo-code","branch":"main","action_type":"file_change","description":"Created job scripts","artifacts":[".aos/job/job.start.sh"],"result":"success"}
{"timestamp":"...","job_id":"AOS__PHASE3_JOB_BINDING","agent_role":"builder","repo":"Robo-code","branch":"main","action_type":"job_end","description":"Job ended: AOS__PHASE3_JOB_BINDING (success)","artifacts":[],"result":"success"}
```

---

## Graceful Degradation

If no job is bound (state file missing):

- `evlog.append.sh` uses `job_id: "UNKNOWN"`
- `job.end.sh` emits `job_end` with `job_id: "UNKNOWN"` and result `aborted`
- **No action is ever blocked**

This ensures observability continues even when job tracking isn't perfectly maintained.
