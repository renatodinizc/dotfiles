---
name: code-review
description: Performs systematic code review on changes, PRs, or diffs. Use when reviewing pull requests, examining code changes, or when asked to review code. Checks for bugs, security issues, performance problems, and readability.
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Code Review Protocol

Systematic review that catches real issues, not stylistic nitpicks.

## Phase 1: Understand Context

Before reviewing any code:
1. Read the PR description or understand the stated goal of the change
2. Identify what problem this code solves
3. Check if there are related tests

## Phase 2: Review Checklist

Work through these categories in order. Only flag issues that are **material** — would cause bugs, security holes, performance problems, or serious maintenance burden.

### Correctness
- Does the code do what it claims to do?
- Are there off-by-one errors, null/undefined access, race conditions?
- Are edge cases handled (empty inputs, boundary values, error states)?
- Does it handle the unhappy path (network failures, invalid data, timeouts)?

### Security
- SQL injection, XSS, command injection, path traversal?
- Are secrets hardcoded or logged?
- Is user input validated at the boundary?
- Are permissions/authorization checks in place?

### Performance
- O(n^2) or worse where O(n) is possible?
- N+1 queries or unbounded data fetching?
- Missing indexes on queried columns?
- Large allocations in hot paths?

### Design
- Does this change belong in this location architecturally?
- Are there existing patterns in the codebase being ignored?
- Is the abstraction level appropriate (not over/under-engineered)?
- Could this be simpler while still solving the problem?

### Maintainability
- Would a new team member understand this code in 6 months?
- Are there misleading names or unclear logic flows?
- Is there duplicated logic that should be consolidated?

## Phase 3: Output Format

Structure the review as:

**Must Fix** — Issues that will cause bugs, security vulnerabilities, or data loss.

**Should Fix** — Issues that will cause problems over time (performance, maintainability).

**Consider** — Suggestions that would improve the code but are not blocking.

For each issue:
- File and line number
- What the problem is (1 sentence)
- Why it matters
- Suggested fix (concrete, not vague)

## Rules

- Do NOT flag style issues that a linter would catch.
- Do NOT suggest adding comments, docstrings, or type annotations unless they fix a real ambiguity.
- Do NOT suggest renaming things unless the current name is actively misleading.
- Praise what's done well (briefly, 1-2 sentences at the end).
- If the code is solid, say so. Do not invent issues to appear thorough.
