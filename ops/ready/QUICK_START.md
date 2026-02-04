# READY CHECK Package - Quick Start

## Three Demo Commands

### 1. PASS Demo
```bash
bash aos.ready.sh ops/ready/READY_DEMO_PASS.sh
```
**Expected:** PASS (exit code 0)
**Block String:** None
**Artifacts:** transcript.log, meta.json, git_status.txt, git_diff_stat.txt, git_log_1_stat.txt

---

### 2. Denylist Block Demo
```bash
bash aos.ready.sh ops/ready/READY_DEMO_DENYLIST_FAIL.sh
```
**Expected:** FAIL (blocked before execution)
**Block String:** `AOS_READY_DENYLIST_BLOCK`
**Artifacts:** None (run directory created but empty)

---

### 3. Network Block Demo
```bash
bash aos.ready.sh ops/ready/READY_NETWORK_OFF_FAIL.sh
```
**Expected:** FAIL (blocked before execution)
**Block String:** `AOS_READY_NETWORK_BLOCK`
**Artifacts:** None (run directory created but empty)

---

### 4. Network Allowed Demo
```bash
bash aos.ready.sh ops/ready/READY_NETWORK_ON_PASS.sh
```
**Expected:** PASS if CRM server running on port 3001, FAIL otherwise
**Block String:** None (execution allowed, may fail due to server unavailability)
**Artifacts:** transcript.log, meta.json, git_status.txt, git_diff_stat.txt, git_log_1_stat.txt

**Note:** Start server: `cd crm-web && node server/crm-export-server.cjs &`

---

## Error Code Reference

- `AOS_READY_METADATA_MISSING` - Script or JSON metadata file not found
- `AOS_READY_DENYLIST_BLOCK` - Denylisted command detected in script
- `AOS_READY_NETWORK_BLOCK` - Network usage detected but policy set to OFF

## Verify Greppable Errors

```bash
bash aos.ready.sh ops/ready/READY_DEMO_DENYLIST_FAIL.sh 2>&1 | grep -q "AOS_READY_DENYLIST_BLOCK" && echo "✓"
bash aos.ready.sh ops/ready/READY_NETWORK_OFF_FAIL.sh 2>&1 | grep -q "AOS_READY_NETWORK_BLOCK" && echo "✓"
```

## Standard Artifacts (Every Run)

All successful executions create:
1. `transcript.log` - Complete stdout/stderr
2. `meta.json` - Metadata with start_time, end_time, exit_code
3. `git_status.txt` - Git status snapshot
4. `git_diff_stat.txt` - Git diff statistics
5. `git_log_1_stat.txt` - Last commit details

Run directory: `ops/runs/<JOB>/<YYYYMMDDHHMMSS>/`
