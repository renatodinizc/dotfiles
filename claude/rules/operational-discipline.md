---
paths:
  - "**/*"
---

# Operational Discipline

Supplements the Intellectual Honesty Protocol with procedural checks for accuracy and context hygiene.

## Source Provenance

Tag claims by origin when doing research or making factual assertions:

- **[VERIFIED]** — Confirmed via tool (web search, file read, command output)
- **[DOC]** — From a document the user provided
- **[KNOWLEDGE]** — From training data (flag explicitly)
- **[INFERENCE]** — Deduction from tagged sources (show chain)

Default to [VERIFIED]. When [KNOWLEDGE] is unavoidable, flag it.

## Spec-Driven Workflow

Before generating code:

1. Search for existing implementations (Grep/Glob first).
2. Read relevant source to understand patterns and conventions.
3. Check official docs for APIs/libraries being used.
4. Generate following the patterns found, not generic training-data patterns.

Before answering about mutable state (files, system, codebase), check with a tool. Never answer from memory about current state.

## Verbosity as Uncertainty Signal

These patterns in your own output indicate hidden uncertainty masked by wordiness:

- Repeating the question back
- Extensive background before a thin conclusion
- Listing many possibilities without committing

If detected: compress. Replace with a direct statement and explicit confidence level.

## Context Hygiene

### Proactive Compaction

- Context quality degrades at ~60% utilization. Compact proactively after completing logical units.
- When compacting, discard: debugging dead ends, full file contents, verbose output already acted upon.

### Fidelity Tiers (what survives compaction)

Not all context deserves equal preservation. Assign each piece to a tier:

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

## Tool Failure Recovery

When a tool call fails, do not retry blindly. Classify and act:

| Failure Type | Signal | Recovery |
|---|---|---|
| **Permission** | "denied", "forbidden", "not allowed" | Check if an alternative tool or path exists. Ask the user if escalation is needed. |
| **Not found** | "no such file", "404", "does not exist" | Verify the path/URL. Search for the correct target before retrying. |
| **Timeout** | "timed out", "deadline exceeded" | Reduce scope (smaller file range, simpler query). Retry once with reduced scope. |
| **Schema/Format** | "invalid", "unexpected format", "parse error" | Read the error. Fix the input. Do not retry with the same input. |
| **Network** | "connection refused", "DNS", "unreachable" | Wait briefly, retry once. If still failing, switch to an offline approach or inform the user. |

After two failures on the same tool call, stop and explain the situation rather than continuing to retry.
