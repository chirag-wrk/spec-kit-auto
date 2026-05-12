---
description: Start the full GS Workflow pipeline from a Jira ticket through spec, repo understanding, planning, tasks, and code generation with approval gates.
---

## User Input

```text
$ARGUMENTS
```

## Parse Input

Extract from `$ARGUMENTS`:
- **JIRA_KEY**: The Jira ticket key (e.g., `PROJ-123`, `TEAM-456`). This is the first argument.
- **REPO_URL**: The GitHub repository URL (e.g., `https://github.com/org/repo`). This is the second argument.

If JIRA_KEY is missing or empty: respond with an error:
```
Error: Jira ticket key is required.
Usage: /start <JIRA-KEY> <GITHUB-REPO-URL>
Example: /start PROJ-123 https://github.com/org/repo
```

If REPO_URL is missing or empty: respond with an error:
```
Error: GitHub repository URL is required.
Usage: /start <JIRA-KEY> <GITHUB-REPO-URL>
Example: /start PROJ-123 https://github.com/org/repo
```

## Execution

Follow the methodology defined in `CLAUDE.md` end-to-end. Execute all 5 stages in order, pausing at each approval gate.

### Stage 1: Spec Understanding

1. Fetch the Jira ticket **JIRA_KEY** using the available Jira MCP tools.
2. Read `templates/spec-template.md`.
3. Generate `artifacts/specs.md` per the Stage 1 instructions in CLAUDE.md.
4. Run spec quality validation.
5. **GATE 1**: Summarize specs.md and ask the user for approval using AskUserQuestion.
   - On approve: proceed to Stage 2.
   - On reject: revise based on feedback and re-present.

### Stage 2: Repo Understanding

1. Analyze the repository at **REPO_URL** (available under `/workspace/repos/`). If not already cloned, clone it.
2. Read `templates/constitution-template.md`.
3. Generate `artifacts/constitution.md` per the Stage 2 instructions in CLAUDE.md.
4. **GATE 2**: Summarize constitution.md and ask the user for approval using AskUserQuestion.
   - On approve: proceed to Stage 3.
   - On reject: revise based on feedback and re-present.

### Stage 3: Planning

1. Read approved `artifacts/specs.md` and `artifacts/constitution.md`.
2. Read `templates/plan-template.md`.
3. Generate `artifacts/plan.md` per the Stage 3 instructions in CLAUDE.md.
4. **GATE 3**: Summarize plan.md and ask the user for approval using AskUserQuestion.
   - On approve: proceed to Stage 4.
   - On reject: revise based on feedback and re-present.

### Stage 4: Task Creation

1. Read all approved artifacts.
2. Read `templates/tasks-template.md`.
3. Generate `artifacts/tasks.md` per the Stage 4 instructions in CLAUDE.md.
4. **GATE 4**: Summarize tasks.md (total tasks, per-story breakdown, MVP scope) and ask the user for approval using AskUserQuestion.
   - On approve: proceed to Stage 5.
   - On reject: revise based on feedback and re-present.

### Stage 5: Code Generation

1. Read all approved artifacts.
2. Create a feature branch in the target repo.
3. Execute tasks phase-by-phase per the Stage 5 instructions in CLAUDE.md.
4. Commit, push, and create a draft PR.
5. Report final results.
