---
description: Create a plan and store it in plan.md.
handoffs:
  - label: Validate Plan Against Spec
    agent: speckit.planaudit
    prompt: Score plan fidelity against spec.md before generating tasks.
    send: true
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
---

## User Input

```text
$ARGUMENTS
```

## Outline

1. Read `.specify/feature.json` to get the feature directory path.

2. **Load context**: `.specify/memory/constitution.md` and `<feature_directory>/spec.md`.

3. Create an implementation plan and store it in `<feature_directory>/plan.md`.
   - Technical context: tech stack, dependencies, project structure
   - Design decisions, architecture, file structure

4. **Mandatory next step**: Run `__SPECKIT_COMMAND_PLANAUDIT__` before `__SPECKIT_COMMAND_TASKS__`.
