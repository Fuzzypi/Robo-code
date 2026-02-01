# AOS Run Wrapper

Command execution wrappers that automatically log to evlog.

## Guarantees

| Property | Guarantee |
|----------|-----------|
| **Best-effort** | If logging fails, the command still runs |
| **No enforcement** | These scripts NEVER block, gate, or fail due to logging |
| **Exit code preserved** | The wrapper returns the command's original exit code |
| **No side effects** | Only adds evlog entries, never modifies files or state |

---

## Scripts

### `run.sh` — Execute Command with Logging

Wraps a single command and logs its execution to evlog.

```bash
./run.sh -- <command...>
```

**What it logs:**
1. Before execution: `action_type: "command"`, `result: "started"`
2. After execution: `action_type: "command"`, `result: "success"` or `"failure"`

**Captured in description:**
- Full command string
- Exit code
- Duration in milliseconds

**Examples:**

```bash
# Simple command
./.aos/run/run.sh -- ls -la

# Build command
./.aos/run/run.sh -- npm run build

# Multi-word command
./.aos/run/run.sh -- git status --short
```

---

### `run.job.sh` — Job-Scoped Command Execution

Combines job binding with command execution. Automatically:
1. Starts the job (`job.start.sh`)
2. Runs the command with logging (`run.sh`)
3. Ends the job with result (`job.end.sh`)

```bash
./run.job.sh <job_id> [agent_role] -- <command...>
```

**Arguments:**
- `job_id` (required): The job identifier
- `agent_role` (optional): Defaults to `"builder"`
- `--`: Separator (required)
- `command...`: The command to execute

**Examples:**

```bash
# Run verification as a job
./.aos/run/run.job.sh AOS__VERIFY -- npm run verify

# Run build with explicit role
./.aos/run/run.job.sh AOS__BUILD builder -- npm run build

# Run tests
./.aos/run/run.job.sh AOS__TEST qa -- npm test
```

**Evlog output for a job run:**

```
[timestamp] job_start  - Job started: AOS__VERIFY
[timestamp] command    - Running: npm run verify
[timestamp] command    - Completed: npm run verify [exit=0, 1234ms]
[timestamp] job_end    - Job ended: AOS__VERIFY (success)
```

---

## Integration with Job Binding

If a job is already bound via `job.start.sh`, `run.sh` will automatically use that job context:

```bash
# Start a job
./.aos/job/job.start.sh AOS__MANUAL builder

# Run multiple commands under that job
./.aos/run/run.sh -- npm install
./.aos/run/run.sh -- npm run lint
./.aos/run/run.sh -- npm run build

# End the job
./.aos/job/job.end.sh success
```

All commands will be logged with `job_id: "AOS__MANUAL"`.

---

## Graceful Degradation

The run wrapper is designed to never block execution:

| Condition | Behavior |
|-----------|----------|
| evlog.append.sh missing | Command runs, no logging |
| Job state missing | Command runs, uses `job_id: "UNKNOWN"` |
| Logging fails | Command runs normally |
| Invalid arguments | Usage message, exit 1 |

---

## Exit Codes

The wrapper **always** returns the original command's exit code:

```bash
./.aos/run/run.sh -- true
echo $?  # 0

./.aos/run/run.sh -- false
echo $?  # 1

./.aos/run/run.sh -- exit 42
echo $?  # 42
```

---

## Use Cases

### CI/CD Integration

Wrap your CI commands to get automatic logging:

```bash
./.aos/run/run.job.sh CI__BUILD -- npm run build
./.aos/run/run.job.sh CI__TEST -- npm test
./.aos/run/run.job.sh CI__DEPLOY -- ./deploy.sh
```

### Agent Self-Explanation

Agents can wrap their commands to explain what they're doing:

```bash
./.aos/run/run.sh -- git checkout -b feature/new-thing
./.aos/run/run.sh -- npm install lodash
./.aos/run/run.sh -- npm run build
```

The evlog will show exactly what commands were run and their results.

### Debugging

After something goes wrong, inspect the evlog:

```bash
./.aos/introspect/evlog.tail.sh 50 | grep command
```

---

## Phase 4 Scope

This is **Phase 4 run wrapper**. It provides:

- ✅ Command execution with logging
- ✅ Job-scoped execution
- ✅ Exit code and duration capture
- ✅ Graceful degradation

It does NOT provide:

- ❌ Command interception or modification
- ❌ Execution blocking or gating
- ❌ Policy enforcement
- ❌ Output capture (stdout/stderr)

Future phases may add output capture, but the wrapper remains best-effort and non-blocking.

---

## Related Documentation

- `.aos/logs/README.md` — Event logging
- `.aos/job/README.md` — Job binding
- `.aos/introspect/README.md` — Log inspection
