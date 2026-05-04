---
description: Evaluate acceptance criteria completeness and traceability in spec.md before planning (shift-left gate).
handoffs:
  - label: Build Technical Plan
    agent: speckit.plan
    prompt: Create a plan for the spec. I am building with...
    send: true
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --spec-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -SpecOnly
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if empty, continue with repo context only).

## Pre-Execution Checks

**Check for extension hooks (before AC audit)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_acaudit` key (if absent, skip silently).
- Apply the same optional vs mandatory hook output pattern as `__SPECKIT_COMMAND_SPECIFY__` uses for `hooks.before_specify`.
- If no hooks are registered or the key is absent, skip silently.

## Goal

Run the **earliest** structured quality gate on `spec.md`: score every acceptance criterion (and coverage of requirements), enforce traceability to success criteria, and **never silently proceed** when the gate is BLOCK. This command runs **after** `__SPECKIT_COMMAND_SPECIFY__` and **before** `__SPECKIT_COMMAND_PLAN__`.

## Operating Constraints

- **Write allowed** only to the artifact paths listed below (create `checklists/` under the feature directory if needed). Do **not** rewrite `spec.md` unless the user explicitly asked you to fix issues in this session; if you propose edits, list them as recommendations in the audit file.
- Treat `.specify/memory/constitution.md` as **non-negotiable** for terminology and project rules when scoring ambiguity.

## Execution Steps

### 1. Resolve paths

Run `{SCRIPT}` once from the repository root and parse JSON for `FEATURE_DIR` (and any other keys returned). Derive:

- `SPEC` = `FEATURE_DIR/spec.md`
- `CONSTITUTION` = `.specify/memory/constitution.md` (from repo root)
- `AGENTS` = `AGENTS.md` (repo root)

For single quotes in shell args, use escape syntax as in other Spec Kit commands.

### 2. Pre-flight (no silent proceed)

Evaluate **before** scoring:

| Check | Severity | Action |
|-------|----------|--------|
| `SPEC` exists and is non-trivially populated | **BLOCK** if missing/empty | Abort scoring; tell user to run `__SPECKIT_COMMAND_SPECIFY__` |
| `CONSTITUTION` exists and is non-empty | **BLOCK** if missing/empty | Record in audit as preflight failure; do not claim PASS |
| `AGENTS` exists at repo root | **WARN** if missing | Record warning; continue scoring if constitution + spec OK |
| `AGENTS` exists but is effectively empty | **WARN** | Same as above |

If any **BLOCK** preflight item fails, write `checklists/ac-audit.md` with section `## Preflight` explaining the failure, set **`GATE: BLOCK`**, and **stop** (no overall score).

### 3. Reproducibility snapshot (deterministic)

From repo root, run the bundled script (same script type as `{SCRIPT}`):

- Bash: `.specify/scripts/bash/record-spec-snapshot.sh`
- PowerShell: `.specify/scripts/powershell/record-spec-snapshot.ps1`

If the script is missing, note that in the audit under `## Notes` and continue.

### 4. Extract from spec.md

Build internal lists (for scoring — summaries go in the audit):

- Functional and non-functional requirements (numbered **FR-01**, **NFR-01**, … if not already numbered).
- Success criteria (**SC-01**, …).
- Acceptance criteria / acceptance scenarios / user-story acceptance tests (**AC-01**, …). If the spec only embeds ACs inside user stories, extract each discrete scenario as its own AC row.

### 5. Per-AC scoring (four dimensions)

For **each** AC (or each discrete acceptance scenario), score **how many** of these four dimensions pass (0–4). Document pass/fail per dimension in a table.

| Dimension | Pass when |
|-----------|-----------|
| **Traceability** | AC maps to at least one explicit requirement or success criterion in `spec.md` (quote the IDs or headings). |
| **Testability** | A tester could decide pass/fail without subjective judgment (measurable, observable, or a clear boolean condition). |
| **Unambiguity** | Single clear interpretation; no unbounded “etc.”, “appropriate”, “fast”, “user-friendly” without definition. |
| **Coverage contribution** | This AC helps cover at least one requirement that would otherwise have zero AC (informational — also compute global Coverage below). |

**Per-AC dimension count**: `dimensions_pass ∈ {0,1,2,3,4}`.

### 6. Global Coverage dimension

Separately from per-AC rows:

- Build the set of requirements (FR + NFR) that must have testable acceptance paths.
- For each requirement, count how many ACs trace to it.
- **Coverage pass** for a requirement: count ≥ 1.
- **Coverage score (0–100)** = 100 × (requirements with ≥1 tracing AC) / (total requirements), or 100 if there are zero requirements (then flag “no requirements listed” as BLOCK).

### 7. Overall score (0–100)

Use this **transparent** formula (document it verbatim in the audit file):

1. **AC quality mean** = average over all ACs of `(dimensions_pass / 4) × 100`.
2. **Overall** = round( 0.5 × **AC quality mean** + 0.5 × **Coverage score** ).

If there are **zero** AC rows extracted, **Overall = 0** and **GATE: BLOCK** (insufficient acceptance criteria).

### 8. Write `checklists/ac-audit.md`

Path: `FEATURE_DIR/checklists/ac-audit.md` (create directory if needed).

Include:

- Date, feature name, link/path to `spec.md`
- Preflight results
- Summary table: each AC, dimensions pass count, trace links (SC-xx / FR-xx)
- **Coverage** subsection: table per requirement → count of tracing ACs
- **Overall score** and formula breakdown
- Optional **`AC_TRACEABILITY.md`**: only if it adds clarity — same directory or under `checklists/`, mapping `AC-xx → SC-xx / FR-xx`
- **`GATE: PASS`** or **`GATE: BLOCK`** with explicit reasons
- If BLOCK: ordered list of **concrete** spec edits needed (bullet points); instruct user to update `spec.md` and re-run `__SPECKIT_COMMAND_ACAUDIT__` (this command)

**Threshold**: Default **PASS** if Overall ≥ **75** and preflight has no BLOCK. Otherwise **BLOCK**. If the user message overrides the threshold via arguments, honor a numeric threshold they supply.

### 9. Report to user

Echo:

- Paths to `checklists/ac-audit.md` and snapshot JSON under `.specify/spec-snapshots/` (if created)
- **GATE** status in bold
- **Mandatory next step**: If PASS → proceed to `__SPECKIT_COMMAND_PLAN__`. If BLOCK → do **not** run plan until spec + audit are resolved.

## Extension hooks (after AC audit)

After reporting, check `.specify/extensions.yml` for `hooks.after_acaudit` using the same optional/mandatory pattern as `hooks.after_specify` in `__SPECKIT_COMMAND_SPECIFY__`.
