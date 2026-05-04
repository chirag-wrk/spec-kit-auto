---
description: Validate that plan.md reflects spec.md (fidelity gate) before generating tasks.md.
handoffs:
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if empty, continue with repo context only).

## Pre-Execution Checks

**Check for extension hooks (before plan audit)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_planaudit` key (if absent, skip silently).
- Apply the same optional vs mandatory hook output pattern as `__SPECKIT_COMMAND_PLAN__` uses for `hooks.before_plan`.
- If no hooks are registered or the key is absent, skip silently.

## Goal

After `__SPECKIT_COMMAND_PLAN__` and **before** `__SPECKIT_COMMAND_TASKS__`, score how well `plan.md` captures the requirements and constraints in `spec.md`, list gaps, optionally propose bounded plan amendments, and **never silently proceed** when the gate is BLOCK.

## Operating Constraints

- **Prefer artifacts-first**: write scores and gaps to disk before editing `plan.md`.
- **Edits to plan.md** are allowed **only** when they are narrowly scoped, explicitly tied to rows in `ASSUMPTIONS.md`, and justified against `spec.md` or `.specify/memory/constitution.md`. Otherwise, output recommendations only.
- Treat the constitution as **non-negotiable**; constitution conflicts → **BLOCK** unless the user explicitly runs a constitution update in a separate step.

## Execution Steps

### 1. Resolve paths

Run `{SCRIPT}` from repo root; parse JSON for `FEATURE_DIR` and `AVAILABLE_DOCS`. Derive absolute paths:

- `SPEC` = `FEATURE_DIR/spec.md`
- `PLAN` = `FEATURE_DIR/plan.md`
- `CONSTITUTION` = `.specify/memory/constitution.md`
- `AGENTS` = `AGENTS.md` (repo root)
- Optional: `FEATURE_DIR/data-model.md`, `FEATURE_DIR/research.md`, `FEATURE_DIR/contracts/`, `FEATURE_DIR/quickstart.md` when present

Abort with a clear error if `SPEC` or `PLAN` is missing (tell the user which prerequisite command to run).

### 2. Extract

**From spec.md**

- Functional + non-functional requirements (stable IDs: FR-xx, NFR-xx).
- Constraints, non-goals, entities/relationships (if present).
- Success criteria (SC-xx) and acceptance criteria / scenarios (AC-xx).

**From plan.md**

- Architectural decisions, stack choices, module boundaries, data flow, testing approach, phased rollout — anything that answers “how” and “where”.

### 3. Per-requirement fidelity score

For **each** requirement row from the spec (FR/NFR):

- **2** = plan contains a clear, consistent architectural decision that addresses the requirement without contradicting constraints.
- **1** = partially addressed (vague module, missing test hook, or implicit only).
- **0** = not addressed or contradicted (including silent conflict with constitution).

**Overall fidelity (0–100)** = round( 100 × sum(scores) / (2 × number_of_requirements) ) when there is at least one requirement; if zero requirements, set fidelity to 0 and **BLOCK** with explanation.

### 4. Write `UNDERSTANDING_GAPS.md`

Path: `FEATURE_DIR/UNDERSTANDING_GAPS.md`.

Sections:

- **Uncovered** — requirements with score 0
- **Partial** — score 1, with what is missing
- **Ambiguity sources** — places where plan language could map to multiple conflicting implementations
- **Constitution / spec conflicts** — if any

### 5. Auto-enrich loop (max 3 attempts)

Document in `ASSUMPTIONS.md` (append or create at `FEATURE_DIR/ASSUMPTIONS.md`):

For each gap iteration `i` in 1..3:

1. Propose the smallest set of **plan amendments** or **explicit assumptions** that would raise the lowest scores.
2. For each assumption row, include: **requirement id**, **assumption text**, **confidence** (0.0–1.0), **rationale**, **iteration**.
3. Re-score **Overall fidelity** *as-if* those assumptions were adopted (clearly label simulated vs applied).

**Apply edits to plan.md** only on iteration ≤ 3 when:

- confidence ≥ **0.85**, and
- the change is a direct fix for a single listed gap, and
- constitution remains satisfied.

Otherwise, keep `plan.md` unchanged and record “proposed amendment” only in `UNDERSTANDING_GAPS.md` / `ASSUMPTIONS.md`.

### 6. Gate decision

- **Threshold**: Default **PASS** if Overall fidelity ≥ **80** and there are **no** constitution conflicts. If the user supplies a numeric threshold in arguments, use it.
- If after **3** iterations fidelity remains below threshold: **`GATE: BLOCK`**, emit a **structured failure** section in `UNDERSTANDING_GAPS.md` (bulleted stop conditions). **Do not** instruct running `__SPECKIT_COMMAND_TASKS__` until PASS.
- If **PASS**: state that `__SPECKIT_COMMAND_TASKS__` may proceed. Summarize residual low-confidence assumptions (if any) for the PR description.

### 7. Report to user

- Paths to `UNDERSTANDING_GAPS.md`, `ASSUMPTIONS.md`, and updated `plan.md` (if touched)
- **GATE: PASS** or **GATE: BLOCK** in bold
- Mandatory next step: PASS → `__SPECKIT_COMMAND_TASKS__`; BLOCK → revise plan/spec and re-run `__SPECKIT_COMMAND_PLANAUDIT__`

## Extension hooks (after plan audit)

Check `.specify/extensions.yml` for `hooks.after_planaudit` using the same optional/mandatory pattern as `hooks.after_plan` in `__SPECKIT_COMMAND_PLAN__`.
