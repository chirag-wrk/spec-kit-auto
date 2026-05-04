---
description: Create a specification and store it in spec.md.
handoffs:
  - label: Run AC Audit Gate
    agent: speckit.acaudit
    prompt: Evaluate acceptance criteria completeness in spec.md before planning.
    send: true
  - label: Build Technical Plan
    agent: speckit.plan
    prompt: Create a plan for the spec. I am building with...
    send: true
---

## User Input

```text
$ARGUMENTS
```

## Outline

1. **Ask the user** for the feature directory path (e.g., `specs/my-feature`). Do not proceed until provided.

2. Create the directory and write `.specify/feature.json`:
   ```json
   { "feature_directory": "<feature_directory>" }
   ```

3. Create a specification from the user input and store it in `<feature_directory>/spec.md`.
   - Overview, functional requirements, user scenarios, success criteria
   - Every requirement must be testable
   - Make informed defaults for unspecified details

4. **Mandatory next step**: Run `__SPECKIT_COMMAND_ACAUDIT__` before `__SPECKIT_COMMAND_PLAN__`.
