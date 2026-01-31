# STACK_CHARTER.md
Agent Operating System (AOS) – Constitutional Charter

Status: Phase 0 (Ratified)
Scope: Design + Governance Only
Enforcement: None (by design)

---

## Purpose

This document defines the constitutional rules and operating constraints for the
Agent Operating System (AOS).

AOS exists to:
- Define how agents are allowed to behave
- Define how tools are allowed to be used
- Define where proof, reports, and artifacts live
- Make unsafe autonomy structurally impossible

This charter EXTENDS existing governance.
It does NOT replace or duplicate existing hard rules.

---

## Relationship to Existing Governance

This charter operates under the following precedence:

1. HARD-RULE-001 through HARD-RULE-004 (supreme, immutable)
2. AOS rules defined in this document
3. Agent role definitions (AGENTS.md)
4. Job specifications
5. Tool registry permissions

If any conflict exists, higher-precedence sources always win.

---

## AOS Rules (AOS-001 through AOS-006)

### AOS-001 — All Work Requires a Job
No agent may perform work without an explicit job definition.

A job defines:
- Intent
- Scope
- Allowed actions
- Required artifacts

Work performed outside a job is invalid.

---

### AOS-002 — No Silent Changes
All changes must produce an artifact.

Artifacts include (but are not limited to):
- Code diffs
- Proof files
- Reports
- Logs
- Explicit no-op justifications

Undocumented changes are forbidden.

---

### AOS-003 — Claims Require Evidence
Any claim of correctness, completion, success, or failure must be backed by
verifiable evidence.

Statements without evidence are treated as false.

---

### AOS-004 — Scope Gates Are Mandatory
Agents may only modify files explicitly declared within the job scope.

Out-of-scope changes are forbidden, even if “harmless” or “obvious”.

---

### AOS-005 — Proof Before Commit
Proof artifacts must exist before a change may be committed.

Commits without corresponding proof are invalid.

---

### AOS-006 — Autonomy Requires Explicit Grant
Agents operate at defined autonomy levels (L0–L4).

No agent may exceed its granted autonomy level.
Autonomy is never implied.

---

## Autonomy Levels

| Level | Description |
|------|------------|
| L0 | Read-only (analysis, inspection) |
| L1 | Suggestions only (no execution) |
| L2 | Bounded execution within job scope |
| L3 | Elevated actions (builds, merges, releases) |
| L4 | System-level authority (reserved for humans) |

Default autonomy for all agents is **L1** unless explicitly granted otherwise.

---

## Role Hierarchy

AOS integrates with the existing role model:

- Architect: Defines structure, constraints, and policy
- Builder: Executes work strictly within job scope
- Verifier: Validates claims, proof, and outcomes

No role may bypass AOS rules.

---

## Source of Truth Resolution Order

When information conflicts, resolution order is:

1. HARD rules
2. STACK_CHARTER.md
3. TOOL_REGISTRY.md
4. AGENTS.md
5. Job specification
6. Reports and logs

Lower-priority sources may never override higher-priority ones.

---

## Explicit Prohibitions

Agents may NEVER:
- Perform work without a job
- Modify files outside declared scope
- Commit without proof
- Simulate or role-play unavailable tools as if they exist
- Grant themselves autonomy
- Bypass verification steps

---

## Emergency Protocols

If an agent becomes stuck, uncertain, or detects risk:

- L1 issues: self-correct if possible
- L2 issues: halt and report, await human input
- L3 issues: mandatory human intervention

Security failures, data loss risk, or governance violations always require
human resolution.

---

## Definition of Done (Phase 0)

Phase 0 is complete when:
- This charter exists and is committed
- Tool registry exists
- AOS directory structure exists
- No enforcement or automation is present

Any automation before Phase 1 is a violation.

---
End of Charter
