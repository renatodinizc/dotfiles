---
paths:
  - "**/*.rs"
  - "**/*.py"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.go"
  - "**/*.rb"
  - "**/*.java"
  - "**/*.kt"
---

# Feature Implementation Protocol

When building features or fixing bugs. The builder's perspective: "what do I need to do for this to be production-ready?"

## Test-First Workflow

Default to red/green TDD.

1. **On entry**: Run the existing test suite first. This locates the harness, reveals project health, and sets the baseline.
2. **Red**: Write a failing test that captures expected behavior or reproduces the bug. Run it. Confirm it fails.
3. **Green**: Write the minimum implementation to pass the test.
4. **Refactor**: Clean up only if unclear. Do not gold-plate.

When manual testing (curl, browser, REPL) reveals an issue, write a failing test that reproduces it before fixing it.

Match existing test style. Read at least two test files before writing new ones.

**Skip TDD for**: exploratory prototypes explicitly marked throwaway, one-off scripts, config changes, docs-only changes. Say why when skipping.

## Pre-Change: Scope the Blast Radius

Before modifying code:

1. **Who consumes this?** List all direct consumers of the function, struct, message, or API being changed. If you cannot enumerate them, search before proceeding.
2. **What crosses a boundary?** If the change touches serialization, message formats, API contracts, or shared state, list all services/components on both sides.
3. **What happens during rollout?** Will old and new versions coexist? Is the change backwards-compatible with in-flight messages/requests?

## Failure Mode Thinking

For changes touching network, storage, or async coordination:

- What happens if the downstream is **slow** (not down, slow)?
- What happens if this operation is **retried**? Is it idempotent?
- What happens if the process **crashes halfway** through this operation?
- What happens under **2x expected load**? What **breaks entirely at 100x** (hundreds of req/s)? Connection pool exhaustion, queue backpressure, cascading timeouts, unbounded buffers.
- Is this endpoint **safe to call twice** with the same input? Retries and at-least-once delivery produce duplicates.

## Observability

Not "are errors logged?" but "how will I know this feature is working correctly in production?"

- **Metrics**: Does this change emit what's needed to understand its behavior? Latency (p50/p95/p99), throughput, error rates, queue depths, resource utilization.
- **Dashboards**: Can someone unfamiliar with this code tell whether the feature is healthy from a Grafana dashboard? If no dashboard exists, flag it.
- **Alerts**: What conditions should page someone? Define thresholds: error rate > X% over Y minutes, latency p99 > Z ms, queue depth growing unboundedly.
- **Deployment validation**: After deploying, what specifically do you check to confirm it works? "Check the logs" is not a plan.

## State Ownership

When introducing or modifying persistent state:

- **State has inertia.** Is this the right place to own this state, or are we creating a future migration?
- **Invalid states**: Does the schema make invalid states unrepresentable, or does it rely on application-layer enforcement that will drift?
