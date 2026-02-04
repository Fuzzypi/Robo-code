# READY Bundles Contract

## Overview
The READY bundle system ensures that all command executions within the AOS system are batch executed with a single approval point. This approach eliminates the need for per-command approvals, promoting efficiency while maintaining auditability and control.

## Components
- **READY_<JOB>.sh**: A script file containing the commands for a specific job.
- **READY_<JOB>.json**: Metadata file that provides additional context, criteria, and permissions related to the job.

## Execution Flow
1. **Generate READY Bundle**:
   - Create `READY_<JOB>.sh` with the necessary commands.
   - Create corresponding `READY_<JOB>.json` detailing job requirements, network policies, and allowed repository roots.

2. **Human Execution**:
   - Run the following command to execute the bundle:
     ```bash
     bash aos.ready.sh ops/ready/READY_<JOB>.sh
     ```
   - The runner processes the script, applying all necessary validations and capturing execution logs.

3. **Output**:
   - A single PASS/FAIL summary is printed, alongside pointers to logs stored in `ops/runs/<JOB>/<timestamp>/`.

## Important Validation Checks
- Both script and metadata must be present and correctly paired.
- Denylisted commands and attempts to breach workspace boundaries are blocked.
- Network operations are prohibited unless specified by metadata.

## Runner Validations & Error Codes

The `aos.ready.sh` runner enforces strict policies and emits stable, greppable error strings:

### Error Codes
- **AOS_READY_METADATA_MISSING**: Script or JSON metadata file not found
- **AOS_READY_DENYLIST_BLOCK**: Denylisted command detected in script
- **AOS_READY_NETWORK_BLOCK**: Network usage detected but policy set to OFF

### Denylist Patterns
The following commands/patterns are blocked:
- `sudo`
- `rm -rf /`
- `rm -rf /tmp/aos_ready_denylist_test`
- `mkfs`
- `dd if=`
- Fork bombs and other destructive patterns

### Network Policy
- Network commands (`curl`, `wget`, `nc`, `netcat`) are blocked by default
- Must explicitly set `"network": "ON"` in metadata JSON to allow network access

## Run Artifacts

Every job execution creates a timestamped run directory with these exact files:
- **transcript.log**: Complete stdout/stderr from job execution
- **meta.json**: Job metadata with start_time, end_time, exit_code
- **git_status.txt**: Git status snapshot from repo_paths[0]
- **git_diff_stat.txt**: Git diff statistics
- **git_log_1_stat.txt**: Last commit details with statistics

Run directory location: `ops/runs/<JOB>/<YYYYMMDDHHMMSS>/`

## Demo Jobs

### 1. READY_DEMO_PASS.sh (Expected: PASS)
**Command:**
```bash
bash aos.ready.sh ops/ready/READY_DEMO_PASS.sh
```

**Expected Result:** PASS (exit code 0)

**Expected Output:**
```
PASS: Job completed successfully (exit code: 0)
  Run directory: ops/runs/READY_DEMO_PASS/YYYYMMDDHHMMSS
  Artifacts: transcript.log, meta.json, git_status.txt, git_diff_stat.txt, git_log_1_stat.txt
```

**Expected Artifacts:**
- `transcript.log`: Demo messages, file creation/cleanup output
- `meta.json`: Metadata with exit_code: 0
- `git_status.txt`: Repository status
- `git_diff_stat.txt`: Diff statistics
- `git_log_1_stat.txt`: Last commit info

**Description:** Safe operations (echo, date, ls, file creation) that complete successfully.

---

### 2. READY_DEMO_DENYLIST_FAIL.sh (Expected: FAIL - Denylist Block)
**Command:**
```bash
bash aos.ready.sh ops/ready/READY_DEMO_DENYLIST_FAIL.sh
```

**Expected Result:** FAIL (blocked before execution)

**Expected Output:**
```
AOS_READY_DENYLIST_BLOCK: Denylisted command detected: sudo
  Found in: ops/ready/READY_DEMO_DENYLIST_FAIL.sh
FAIL: Denylist violation. Run directory: ops/runs/READY_DEMO_DENYLIST_FAIL/YYYYMMDDHHMMSS
```

**Expected Block String:** `AOS_READY_DENYLIST_BLOCK`

**Expected Artifacts:**
- Run directory created but job never executes
- `transcript.log`: Not created (blocked before execution)
- `meta.json`: Not created (blocked before execution)
- Git files: Not created (blocked before execution)

**Description:** Contains `sudo true` command which is denylisted and blocked by runner.

---

### 3. READY_NETWORK_OFF_FAIL.sh (Expected: FAIL - Network Block)
**Command:**
```bash
bash aos.ready.sh ops/ready/READY_NETWORK_OFF_FAIL.sh
```

**Expected Result:** FAIL (blocked before execution)

**Expected Output:**
```
AOS_READY_NETWORK_BLOCK: Network usage detected but policy set to OFF.
  Script: ops/ready/READY_NETWORK_OFF_FAIL.sh
  Network policy: OFF
FAIL: Network policy violation. Run directory: ops/runs/READY_NETWORK_OFF_FAIL/YYYYMMDDHHMMSS
```

**Expected Block String:** `AOS_READY_NETWORK_BLOCK`

**Expected Artifacts:**
- Run directory created but job never executes
- `transcript.log`: Not created (blocked before execution)
- `meta.json`: Not created (blocked before execution)
- Git files: Not created (blocked before execution)

**Description:** Contains `curl` command while network policy is OFF, blocked by runner.

---

### 4. READY_NETWORK_ON_PASS.sh (Expected: PASS/FAIL depending on server)
**Command:**
```bash
bash aos.ready.sh ops/ready/READY_NETWORK_ON_PASS.sh
```

**Expected Result:** 
- PASS if CRM export server is running on port 3001
- FAIL if server is not running (exit code 1, not a policy block)

**Expected Output (Server Running):**
```
PASS: Job completed successfully (exit code: 0)
  Run directory: ops/runs/READY_NETWORK_ON_PASS/YYYYMMDDHHMMSS
  Artifacts: transcript.log, meta.json, git_status.txt, git_diff_stat.txt, git_log_1_stat.txt
```

**Expected Output (Server Not Running):**
```
FAIL: Job exited with error (exit code: 1)
  Run directory: ops/runs/READY_NETWORK_ON_PASS/YYYYMMDDHHMMSS
  Check transcript.log for details
```

**Expected Artifacts:**
- `transcript.log`: Health check attempt and result
- `meta.json`: Metadata with exit_code (0 or 1)
- `git_status.txt`: Repository status
- `git_diff_stat.txt`: Diff statistics
- `git_log_1_stat.txt`: Last commit info

**Description:** Performs network health check with explicit `"network": "ON"` policy. Demonstrates that network is allowed when properly configured.

**Note:** To ensure PASS, start the CRM export server first:
```bash
cd crm-web && node server/crm-export-server.cjs &
```

## Sample Bundle Contents
- Use templates `READY_TEMPLATE.sh` and `READY_TEMPLATE.json` as starting points.

## Verification Commands

Run all demos in sequence:
```bash
# Should PASS
bash aos.ready.sh ops/ready/READY_DEMO_PASS.sh

# Should FAIL with AOS_READY_DENYLIST_BLOCK
bash aos.ready.sh ops/ready/READY_DEMO_DENYLIST_FAIL.sh

# Should FAIL with AOS_READY_NETWORK_BLOCK
bash aos.ready.sh ops/ready/READY_NETWORK_OFF_FAIL.sh

# Should PASS if server running, FAIL otherwise (not a policy block)
bash aos.ready.sh ops/ready/READY_NETWORK_ON_PASS.sh
```

Verify error strings are greppable:
```bash
bash aos.ready.sh ops/ready/READY_DEMO_DENYLIST_FAIL.sh 2>&1 | grep -q "AOS_READY_DENYLIST_BLOCK" && echo "✓ Denylist block detected"
bash aos.ready.sh ops/ready/READY_NETWORK_OFF_FAIL.sh 2>&1 | grep -q "AOS_READY_NETWORK_BLOCK" && echo "✓ Network block detected"
```

---

## Artifact Guarantees (Updated)

**Always created** (even on early validation failures):
- `ops/runs/<JOB>/<timestamp>/transcript.log` - Complete execution log including validation errors
- `ops/runs/<JOB>/<timestamp>/meta.json` - Job metadata with timing (created after execution)
- `ops/runs/<JOB>/<timestamp>/git_status.txt` - Git status snapshot
- `ops/runs/<JOB>/<timestamp>/git_diff_stat.txt` - Git diff statistics  
- `ops/runs/<JOB>/<timestamp>/git_log_1_stat.txt` - Latest commit info

**Critical:** `transcript.log` is created **immediately** after run directory creation, ensuring all validation messages (including `AOS_READY_METADATA_MISSING`, `AOS_READY_DENYLIST_BLOCK`, `AOS_READY_NETWORK_BLOCK`) are captured even if early validation fails.

## Environment Variables

The runner exports:
- `AOS_RUN_DIR`: Full path to the run artifact directory (e.g., `ops/runs/READY_DEMO_PASS/20260204171128`)

Job scripts can use `$AOS_RUN_DIR` to write additional artifacts or read from `transcript.log`.

## Dependencies

**Required:** bash, git, grep, sed (standard on macOS/Linux)

**Optional:** jq (for enhanced metadata merging; runner falls back to simple JSON generation if `jq` not available)

## Repository Root Detection

The runner reads `repo_roots` from the JSON metadata:
- If `"repo_roots": ["."]` or missing, defaults to current directory  
- Git snapshots are taken from the specified repo root

Example metadata:
```json
{
  "job_name": "MY_JOB",
  "repo_roots": ["."],
  "network": "OFF"
}
```
