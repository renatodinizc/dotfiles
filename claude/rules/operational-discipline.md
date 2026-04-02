---
paths:
  - "**/*"
---

# Operational Discipline

## Spec-Driven Workflow

Before generating code:

1. Search for existing implementations (Grep/Glob first).
2. Read relevant source to understand patterns and conventions.
3. Check official docs for APIs/libraries being used.
4. Generate following the patterns found, not generic training-data patterns.

Before answering about mutable state (files, system, codebase), check with a tool. Never answer from memory about current state.

## Context Hygiene

### Proactive Compaction

- Compact proactively when remaining context drops below 40%. Check the statusline `ctx:%` value, which shows remaining (not used) percentage.
- When compacting, discard: debugging dead ends, full file contents, verbose output already acted upon.

### Fidelity Tiers (what survives compaction)

| Tier | Retention | Examples |
|---|---|---|
| **FULL** (verbatim) | Active decisions, current failing tests, blocked items, user corrections | "User said don't mock the DB", "Test X fails with error Y" |
| **COMPRESSED** (summarized) | Completed exploration, resolved discussions, background research | "Explored 3 auth approaches, chose JWT because..." |
| **STUB** (one-line reference) | Files read for context, successful tool outputs, dead ends | "Read src/auth.rs (450 lines, token validation logic)" |

Default to STUB. Promote to COMPRESSED only if the detail would change a future decision. Promote to FULL only if losing it would cause a wrong action.

### Post-Compaction Recovery

After compaction fires (auto or manual), before continuing work:

1. State what you were doing and what the next step is.
2. Check whether FULL-tier items survived. If a decision rationale or failing test is missing, re-read the source.
3. If you cannot reconstruct the current task from what remains, say so. Do not silently proceed with degraded context.

### Brevity Bias Guard

Summaries naturally drop non-obvious details. When compressing, ask: "What would someone need to know to disagree with the decision made here?" If the answer isn't in the summary, add it.
