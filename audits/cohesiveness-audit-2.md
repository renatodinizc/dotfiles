# Cohesiveness Audit - Second Pass

Date: 2026-04-01

## Context

This audit ran after a first pass (commit f346c04) that addressed the major redundancies:
deduplicated anti-sycophancy rules, compressed Research & Content, removed usage-journal,
removed CLI tools list, fixed /pre-mortem invocation, cleaned up deep-dive skill.

## Key Finding: F1 False Positive

Initial analysis flagged `claude/CLAUDE.md` as being loaded twice (global + project). Investigation
revealed this is NOT the case. `~/.claude/CLAUDE.md` is a symlink to `claude/CLAUDE.md` via
`install.sh`. Claude Code loads it once via the global path. There is no project-level CLAUDE.md
at standard paths (`CLAUDE.md` or `.claude/CLAUDE.md` in project root).

## Token Budget (unchanged from Phase 1)

| Scenario | Tokens | % of 200k |
|---|---|---|
| Always loaded | ~2,981 | 1.5% |
| Typical coding session | ~4,286 | 2.1% |
| All rules match (Rust) | ~4,687 | 2.3% |

Budget is well within acceptable limits.

## Changes Applied

### R2: Explicit protocol activation order (CLAUDE.md)
- Added "Protocol Activation Order" section defining the sequence:
  Emotional Context > Clarification-First > IHP Tiers 1-3 > Plan > Execute
- Previously this was scattered across hints in 3 files. Now stated once.
- Removed redundant "for non-trivial tasks" workflow bullet (now covered by the ordering).

### R3: Move Emotional Context earlier in IHP (intellectual-honesty.md)
- Moved from end of file (most vulnerable to truncation) to right after Anti-Sycophancy Rules.
- Emotional Context is supposed to take priority over all other IHP tiers.
  Its position should reflect that priority.

### R4: Tighten PreToolUse hook regex (settings.json)
- Added patterns: `rm -rf ~`, `rm -rf .`, `rm -rf *`, `chmod 777 /`
- Previously only caught `rm -rf /`.

### R5: Remove duplicate integration note (CLAUDE.md)
- Removed "When IHP Tier 3 also triggers, merge both into one conversation" from
  Clarification-First techniques. This is already stated in IHP Tier 3 (line 103)
  and now also in the Protocol Activation Order (step 3).

## Remaining Low-Priority Items (not acted on)

- Feature-implementation and code-review skill share failure mode questions (by design, skill needs self-contained agent prompts)
- Researcher agent repeats some deep-dive methodology (minor, ~100 tokens)
- detect-project.sh only detects Rust projects (functional but incomplete)
- context7 MCP configured but unreferenced (uncertain if used)
