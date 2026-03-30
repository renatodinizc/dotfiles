---
paths:
  - "**/*"
---

# Context Management Protocol

## Proactive Compaction

- Context quality degrades at ~60% utilization, well before auto-compact triggers at ~95%.
- After completing each logical unit of work (feature done, bug fixed, research complete), consider whether compaction would help.
- When compacting, preserve: list of modified files, architectural decisions with rationale, current task status, and blocked items. Discard: debugging dead ends, full file contents (re-read from disk), verbose command output.

## Session Discipline

- One workstream per session. Use `/clear` between unrelated tasks.
- Use subagents (researcher, debugger) for exploration to keep the main context clean.
- Read specific file sections (`offset` + `limit`) instead of entire files when possible.
- Do not pre-load files speculatively. Read on demand.

## Compaction Preservation Rules

When compacting, always preserve:
- Full list of modified files with one-line descriptions
- Architectural decisions and their rationale
- Failing tests and current error messages
- Blocked items and dependencies
- Current task checklist and completion status

When compacting, always discard:
- Debugging dead ends and rejected approaches
- Full file contents (re-read from disk if needed)
- Verbose command output already acted upon
