# AOS READY Runner Fix - Deliverables

## Modified Files

1. **aos.ready.sh** - Core runner improvements:
   - ✅ Creates `transcript.log` immediately after run directory creation
   - ✅ Exports `AOS_RUN_DIR` environment variable for job scripts
   - ✅ No longer requires `jq` (falls back to simple JSON if not available)
   - ✅ Uses grep/sed for JSON extraction (network policy, repo_roots)
   - ✅ All validation errors are logged to transcript.log via `log()` helper
   - ✅ Preserves greppable block strings: `AOS_READY_METADATA_MISSING`, `AOS_READY_DENYLIST_BLOCK`, `AOS_READY_NETWORK_BLOCK`

2. **ops/ready/README.md** - Updated documentation:
   - ✅ Documents artifact guarantees (transcript.log always created)
   - ✅ Documents `AOS_RUN_DIR` environment variable
   - ✅ Documents dependency requirements (bash/git/grep/sed required, jq optional)
   - ✅ Documents repo_roots detection behavior

## Created Files

3. **ops/ready/READY_SHOGUN_VERIFY.sh** - Verification job that tests:
   - AOS_RUN_DIR is set
   - transcript.log exists and is writable
   - All expected artifacts are present

4. **ops/ready/READY_SHOGUN_VERIFY.json** - Metadata for verify job

5. **ops/ready/READY_SHOGUN_CHECKPOINT.sh** - Checkpoint job that:
   - Verifies repo is clean
   - Creates checkpoint commit
   - Captures before/after git status

6. **ops/ready/READY_METADATA_MISSING_TEST.sh** - Test case for metadata validation failure
   - Intentionally has no matching .json file
   - Used to verify transcript.log is created even on early validation failures

---

## READY - Verification Commands

### Test 1: Normal Execution (should PASS)
```bash
bash aos.ready.sh ops/ready/READY_SHOGUN_VERIFY.sh
```
**Expected:** PASS with exit code 0  
**Validates:** AOS_RUN_DIR set, transcript.log exists and writable

### Test 2: Checkpoint Commit (should PASS if repo clean)
```bash
bash aos.ready.sh ops/ready/READY_SHOGUN_CHECKPOINT.sh
```
**Expected:** PASS with exit code 0, creates checkpoint commit  
**Validates:** Clean repo check, commit creation

### Test 3: Metadata Missing (should FAIL with transcript)
```bash
bash aos.ready.sh ops/ready/READY_METADATA_MISSING_TEST.sh
```
**Expected:** FAIL with `AOS_READY_METADATA_MISSING` error  
**Validates:** transcript.log created even for early validation failure

### Verify transcript exists on metadata failure:
```bash
ls -la ops/runs/READY_METADATA_MISSING_TEST/*/transcript.log
```
**Expected:** File exists and contains `AOS_READY_METADATA_MISSING` message

---

## Test Results (2026-02-04 17:22:30)

✅ **Test 1: READY_SHOGUN_VERIFY**  
```
PASS: Job completed successfully (exit code: 0)
  Run directory: ops/runs/READY_SHOGUN_VERIFY/20260204172230
  Artifacts: transcript.log, meta.json, git_status.txt, git_diff_stat.txt, git_log_1_stat.txt
```

✅ **Test 2: READY_SHOGUN_CHECKPOINT**  
```
PASS: Job completed successfully (exit code: 0)
  Run directory: ops/runs/READY_SHOGUN_CHECKPOINT/20260204172230
  Artifacts: transcript.log, meta.json, git_status.txt, git_diff_stat.txt, git_log_1_stat.txt
```

✅ **Test 3: READY_METADATA_MISSING**  
```
AOS_READY_METADATA_MISSING: Required job script or metadata missing.
  Expected script: ops/ready/READY_METADATA_MISSING_TEST.sh
  Expected metadata: ops/ready/READY_METADATA_MISSING_TEST.json
FAIL: Metadata validation failed. Run directory: ops/runs/READY_METADATA_MISSING_TEST/20260204172230
```

✅ **Transcript exists:**  
```
-rw-r--r--@ 1 fuzzypi  staff  294 Feb  4 17:22 ops/runs/READY_METADATA_MISSING_TEST/20260204172230/transcript.log
```

---

## Key Improvements Summary

| Requirement | Status | Implementation |
|------------|--------|----------------|
| Always write transcript.log | ✅ | Created immediately after `mkdir -p "$RUN_DIR"` |
| Export AOS_RUN_DIR | ✅ | `export AOS_RUN_DIR="$RUN_DIR"` on line 25 |
| No jq dependency | ✅ | Uses grep/sed with jq fallback for metadata |
| Greppable block strings | ✅ | Preserved exactly as specified |
| Early failure logging | ✅ | `log()` helper writes to both stdout and transcript |
| Metadata pairing | ✅ | `${JOB_SCRIPT%.sh}.json` deterministic pairing |
| Repo root detection | ✅ | Reads `repo_roots[0]` with grep/sed, defaults to "." |

---

## Single Command Verification

```bash
# Run all three tests in sequence
bash aos.ready.sh ops/ready/READY_SHOGUN_VERIFY.sh && \
bash aos.ready.sh ops/ready/READY_SHOGUN_CHECKPOINT.sh && \
bash aos.ready.sh ops/ready/READY_METADATA_MISSING_TEST.sh 2>&1 | grep -q "AOS_READY_METADATA_MISSING" && \
ls ops/runs/READY_METADATA_MISSING_TEST/*/transcript.log >/dev/null 2>&1 && \
echo "✅ ALL TESTS PASSED"
```

**Expected output:** `✅ ALL TESTS PASSED`

This single command validates:
1. Normal execution works (VERIFY passes)
2. Checkpoint works with clean repo
3. Metadata missing fails with proper error
4. Transcript created even on early failure
