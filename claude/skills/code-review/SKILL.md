---
name: code-review
description: Performs systematic code review on changes, PRs, or diffs. Use when reviewing pull requests, examining code changes, or when asked to review code. Scopes the review to the change type, actively investigates (traces consumers, reads schemas), and surfaces the questions nobody asked.
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Code Review Protocol

Not just reading the diff. Investigating what the diff means for the system.

## Phase 1: Scope the Review

Read the diff. Classify the change before reviewing:

| Type | Signal | What matters most |
|---|---|---|
| **Leaf code** | Internal logic, private functions, no API/schema change | Correctness, performance |
| **Boundary code** | API endpoints, schema, message formats, public interfaces | Backwards compatibility, consumer impact, rollout |
| **Infrastructure** | Deployment, config, CI/CD, Dockerfile | Rollout safety, reversibility, environment parity |
| **Cross-cutting** | Touches multiple services or shared libraries | Ownership, coupling, coordination |

A change can be multiple types. Apply the checks for each type that matches. Skip checks for types that don't.

## Phase 2: Investigate

Do not just read the diff and opine. Use tools to verify.

**For boundary changes:**
1. Grep for all consumers of the changed API, struct, message, or table. List them.
2. Read at least one consumer to verify compatibility.
3. If the change modifies a schema or message format, check what happens to data already in the pipeline.

**For data flow changes (producers, consumers, shared state):**
1. Trace data from origin to final consumer. Name each hop.
2. At each hop, state what happens on failure (timeout, crash, corrupt data).
3. Check backwards compatibility with in-flight data.

**For new endpoints or features:**
1. Check if metrics/instrumentation exist (grep for metrics libraries, logging patterns).
2. Check if tests cover the unhappy path, not just the happy path.

**For infrastructure changes:**
1. Check if old and new versions can coexist during rollout.
2. Verify the change is reversible (can be rolled back without data loss).

If any investigation reveals unknown territory, say so explicitly. Do not guess.

## Phase 3: Parallel Review

After scoping and investigation, spawn three specialist subagents **in parallel** using the Agent tool. Pass each agent the diff, the change classification from Phase 1, and any findings from Phase 2.

Each agent should return a flat list of findings. Each finding: file and line, what the problem is (1 sentence), why it matters, severity (must-fix / should-fix / question).

### Agent 1: Security Reviewer

> You are reviewing a code change for security issues. Only flag material problems.
>
> Check for:
> - Injection vectors: SQL, XSS, command injection, path traversal
> - Secrets hardcoded or logged
> - User input validated at the boundary
> - Authorization checks in place
> - For boundary changes: auth/authz on new or modified endpoints
>
> Do NOT flag style issues or theoretical concerns. Every finding must cite a specific line and a concrete attack vector or risk.

### Agent 2: Performance Reviewer

> You are reviewing a code change for performance issues. Only flag material problems.
>
> Check for:
> - O(n^2) or worse where O(n) is possible
> - N+1 queries or unbounded data fetching
> - Missing indexes on queried columns
> - Large allocations in hot paths
> - For growing tables: at what scale do index changes degrade?
> - Rate limits: can one caller saturate the system?
>
> Do NOT flag micro-optimizations. Every finding must cite a specific line and explain the scaling impact.

### Agent 3: Correctness & Systems Reviewer

> You are reviewing a code change for correctness and systems-level concerns. Only flag material problems.
>
> **Correctness:**
> - Does the code do what it claims?
> - Off-by-one errors, null/undefined access, race conditions?
> - Edge cases: empty inputs, boundary values, error states?
> - Unhappy path: network failures, invalid data, timeouts?
>
> **Failure modes** (non-trivial changes only):
> - What happens if downstream is slow (not down, slow)?
> - Is this operation idempotent if retried?
> - What happens if the process crashes halfway?
> - At 100x load, what breaks?
>
> **Rollout** (boundary/infrastructure changes only):
> - Expand-Contract: all three phases present, or hard cutover?
> - Can this be rolled back immediately?
> - For schema migrations: what locks are acquired?
>
> **Observability:**
> - Does this change emit metrics needed to know it's working?
> - Are failure conditions alertable?
>
> **Cross-service** (boundary/cross-cutting changes only):
> - Is synchronous coupling necessary or just the default?
> - Is a service becoming a cross-domain orchestrator?
>
> Do NOT flag style issues. Every finding must cite a specific line or architectural concern with concrete impact.

All three agents have access to: Read, Grep, Glob, Bash. They should actively investigate (grep for consumers, read related files), not just opine on the diff.

## Phase 4: Verdict

Structure the output as:

### Must Fix
Issues that will cause bugs, security vulnerabilities, data loss, or production incidents.

### Should Fix
Issues that will cause problems over time: performance degradation, maintenance burden, observability gaps.

### Questions for the Author
Systems-level concerns from the subagents that surfaced material questions. Framed as questions, not demands. These may change the approach, not just the implementation.

### What's Done Well
Brief (1-2 sentences). Genuine, not performative. Skip if nothing stands out.

---

For each issue: file and line number, what the problem is (1 sentence), why it matters, and a concrete suggested fix.

## Rules

- Do NOT flag style issues that a linter would catch.
- Do NOT suggest adding comments, docstrings, or type annotations unless they fix a real ambiguity.
- Do NOT suggest renaming things unless the current name is actively misleading.
- Do NOT invent issues to appear thorough. If the code is solid, say so.
- Scale the review to the change. A one-line bug fix does not need failure mode analysis.
