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

## Phase 3: Standard Review

Work through these. Only flag **material** issues.

### Correctness
- Does the code do what it claims?
- Off-by-one errors, null/undefined access, race conditions?
- Edge cases: empty inputs, boundary values, error states?
- Unhappy path: network failures, invalid data, timeouts?

### Security
- Injection vectors: SQL, XSS, command, path traversal?
- Secrets hardcoded or logged?
- User input validated at the boundary?
- Authorization checks in place?

### Performance
- O(n^2) or worse where O(n) is possible?
- N+1 queries or unbounded data fetching?
- Missing indexes on queried columns?
- Large allocations in hot paths?

## Phase 4: Staff-Engineer Questions

These are not bugs. They are the questions that might change the approach entirely. Only raise them when the change is non-trivial and the question is material.

**Failure modes:**
- What happens if the downstream is slow (not down, slow)?
- What happens if this operation is retried? Is it idempotent?
- What happens if the process crashes halfway?
- At 100x load, what breaks? Connection pools, queues, memory?

**Cross-service concerns** (only for boundary/cross-cutting changes):
- Is synchronous coupling necessary, or is it the default? Sync means: downstream slow = upstream slow.
- Is a service becoming a cross-domain orchestrator?
- Is this service coupling directly to another service's data model?
- Where is the end-to-end SLA defined?

**Rollout** (only for boundary/infrastructure changes):
- Expand-Contract: are all three phases present (expand, migrate, contract), or is this a hard cutover?
- Can this be rolled back immediately if something breaks?
- For schema migrations on live tables: what locks are acquired?

**Observability:**
- Does this change emit the metrics needed to know it's working? Latency, throughput, error rates.
- How does the author know this is healthy in production? If the answer is vague, flag it.
- Are failure conditions alertable with specific thresholds?

**Scaling:**
- For index changes on growing tables: at what scale does this degrade?
- If "strong consistency" is claimed: which specific guarantee per operation?
- Are rate limits enforced? Can one caller saturate the system?

## Phase 5: Verdict

Structure the output as:

### Must Fix
Issues that will cause bugs, security vulnerabilities, data loss, or production incidents.

### Should Fix
Issues that will cause problems over time: performance degradation, maintenance burden, observability gaps.

### Questions for the Author
The staff-engineer questions from Phase 4 that surfaced material concerns. Framed as questions, not demands. These may change the approach, not just the implementation.

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
