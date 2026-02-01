# AOS Guard - Soft Enforcement Guardrails

## Philosophy

**Warn, don't block.**

AOS Guard implements *soft enforcement*: it detects problematic states and warns loudly, but **never prevents execution**. This approach:

- Maintains developer velocity
- Builds awareness of best practices
- Avoids frustrating false positives
- Allows gradual adoption of workflow discipline

## Why Enforcement is Deferred

Hard enforcement (blocking execution, failing CI) is powerful but requires:

1. **High confidence** in the rules
2. **Low false-positive rate**
3. **Clear escape hatches**
4. **Team buy-in**

Before implementing hard gates, we need to:

- Collect data on which warnings are most common
- Identify patterns that lead to actual problems
- Build trust in the guard's accuracy

Soft enforcement lets us learn without disrupting work.

## What Gets Checked

| Check | Detects | Why It Matters |
|-------|---------|----------------|
| **Job not started** | No active job context | Missing job binding reduces traceability |
| **Dirty working tree** | Uncommitted files | May commit unintended changes |
| **Detached HEAD** | Not on a branch | Commits may be lost |
| **Subtree out of sync** | ops/aos vs aos-core | Drift from canonical AOS |
| **Missing evlog** | No observability log | Can't reconstruct what happened |
| **Missing proof dir** | Active job has no proof | Accountability gap |

## Interpreting Warnings

When you see a guard warning:

```
⚠️  AOS GUARD WARNING
- Job not started
- Working tree dirty (3 files)
```

**Ask yourself:**

1. **Is this intentional?** Maybe you're mid-work and this is fine.
2. **Should I fix it now?** Quick fixes (commit, stage) might be worth it.
3. **Is this a recurring pattern?** Consider addressing the root cause.

**Do not:**

- Panic — the warning is informational
- Ignore all warnings — they exist for a reason
- Disable the guard — you'll lose visibility

## Usage

### Automatic (via run wrappers)

The guard runs automatically before every AOS run command:

```bash
./.aos/run/run.sh -- ls -la
./.aos/run/run.job.sh AOS__EXAMPLE -- npm run build
```

### Manual

Run the guard directly:

```bash
# Full output
.aos/guard/aos.guard.sh

# Only output if warnings exist
.aos/guard/aos.guard.sh --quiet
```

## Exit Codes

**Always 0.** This is soft enforcement — we never block.

If you need hard enforcement, see Phase 12 (Hard Gates), which is opt-in and explicit.

## Evlog Integration

Guard checks are logged to the evlog:

```json
{
  "action_type": "guard_check",
  "result": "warnings",  // or "clean"
  "description": "Guard check: 2 warning(s)"
}
```

This allows post-hoc analysis of warning frequency.

## Future Considerations

When data shows clear patterns, we may add:

- **Severity levels** (info, warning, error)
- **Warning categories** (git, job, observability)
- **Threshold-based escalation** (warn 3x, then suggest fix)
- **Opt-in hard mode** (fail on specific warnings)

For now, we observe and learn.

---

*Part of AOS v1.1 - Soft Enforcement Phase*
