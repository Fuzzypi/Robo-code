# TOOL_REGISTRY.md
Agent Operating System (AOS) – Tool Registry

Status: Phase 0 (Design Only)
Scope: Interface + Permission Definition
Implementation: None

---

## Purpose

This document defines:
- Which tools exist
- What permissions they require
- How tools may be invoked
- Which tools are placeholders for future phases

No tool listed here is implicitly available.
Availability always depends on explicit implementation and authorization.

---

## Part I — Existing Tool Classes

### agent.*
Purpose: Agent lifecycle and execution helpers.

Permissions:
- Read: Allowed
- Write: Restricted
- Execute: Job-scoped only

Notes:
- agent tools may never bypass job or scope rules
- agent tools cannot grant autonomy

---

### repo.*
Purpose: Repository inspection and modification.

Permissions:
- Read: Allowed
- Write: Job-scoped only
- Execute: Forbidden

Notes:
- All writes must be within declared job scope
- Proof required for all modifications

---

### fs.*
Purpose: Filesystem access.

Permissions:
- Read: Job-scoped
- Write: Job-scoped
- Execute: Forbidden

Notes:
- No access outside declared paths
- Temporary files must be documented

---

### shell.*
Purpose: Command execution.

Permissions:
- Read: N/A
- Write: N/A
- Execute: Highly restricted

Notes:
- Execution requires explicit job approval
- Destructive commands require human authorization

---

### net.*
Purpose: Network access.

Permissions:
- Read: Restricted
- Write: Restricted
- Execute: Forbidden

Notes:
- External calls require explicit allowlisting
- No data exfiltration without approval

---

## Part II — Future Tool Slots (Interface Only)

The following tools are defined as interfaces only.
They are NOT implemented in Phase 0.

Agents may not simulate or role-play these tools.

---

### trellis.*
Purpose: Persistent memory across sessions.

Interfaces:
- trellis.remember
- trellis.recall

Status: Not implemented

---

### primer.*
Purpose: Automatic repository context generation.

Interfaces:
- primer.context

Status: Not implemented

---

### sherlock.*
Purpose: Observability and agent behavior inspection.

Interfaces:
- sherlock.observe

Status: Not implemented

---

### evlog.*
Purpose: Structured event logging.

Interfaces:
- evlog.emit

Status: Not implemented

---

### shogun.*
Purpose: Multi-agent coordination.

Interfaces:
- shogun.coordinate

Status: Not implemented

---

### veritas.*
Purpose: Git-native task and proof management.

Interfaces:
- veritas.task

Status: Not implemented

---

### openclaw.*
Purpose: Selective skill injection.

Interfaces:
- openclaw.inject

Status: Not implemented

---

## Part III — Permission Matrix

| Tool Class | Read | Write | Execute |
|-----------|------|-------|---------|
| agent.* | Yes | Restricted | Job-scoped |
| repo.* | Yes | Job-scoped | No |
| fs.* | Job-scoped | Job-scoped | No |
| shell.* | N/A | N/A | Restricted |
| net.* | Restricted | Restricted | No |
| future tools | No | No | No |

---

## Part IV — Invocation Rules

- All tool use must occur within an active job
- Tool use must respect declared scope
- Tool output must be captured as an artifact
- Failed tool invocations must be reported
- Tools may never grant autonomy

---

## Phase 0 Constraints

- No tool enforcement is active
- No future tool may be simulated
- Registry defines permissions only

Any deviation before Phase 1 is a violation.

---
End of Registry
