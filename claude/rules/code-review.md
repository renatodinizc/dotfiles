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

# Code Review Protocol

When reviewing PRs or code changes. The reviewer's perspective: "what did the author miss?"

## Data Flow Tracing

Before approving changes to message producers, consumers, or shared data structures:

1. Trace data from **origin to final consumer**. Name each hop.
2. At each hop, state what happens if it **fails** (timeout, crash, corrupt data).
3. Is the change **backwards-compatible** with data already in the pipeline?
4. If any answer is unknown, read the relevant code before approving.

## Cross-Service Concerns

- **Temporal coupling**: Is synchronous request-response truly required, or does it exist by default? Sync calls mean: if downstream is slow, upstream is slow.
- **Orchestrator creep**: Is a service becoming a cross-domain orchestrator? That's tight coupling disguised as a service.
- **Model coupling**: Is this service consuming another service's data model directly? A schema change in the dependency becomes a deployment dependency.
- **SLA ownership**: For multi-component workflows, where is the end-to-end SLA defined? Without one, slow is indistinguishable from broken.
- **Idempotency**: Is every externally-facing endpoint safe to call twice with the same input?

## Backwards Compatibility and Rollout

- **Expand-Contract**: For schema changes, API renames, or contract changes, are all three phases present? Expand (support old + new), migrate (move consumers), contract (remove old). Or is this a hard cutover?
- **Coexistence**: Will old and new versions run simultaneously during deployment? What happens to in-flight requests?
- **Reversibility**: Can this change be rolled back immediately if something breaks?
- **Lock behavior**: For schema migrations on live tables, what locks does this acquire? Can concurrent transactions proceed?

## Failure Modes

- What happens if the downstream is **slow**?
- What happens if this operation is **retried**?
- What happens if the process **crashes halfway**?
- At **100x load**, what breaks? Connection pools, queues, memory, timeouts?
- Are read failures and write failures analyzed **separately**? They have different mitigations.

## Observability Check

- Does this change emit the metrics needed to monitor it? Latency, throughput, error rates.
- After deploying, how does the author know it's working? If the answer is vague, flag it.
- Are error conditions alertable with specific thresholds, or will they fail silently?

## Scaling Awareness

- **Index impact**: For indexing changes on growing tables, at what scale does this degrade or cause write amplification?
- **Consistency precision**: If "strong consistency" is claimed, which specific guarantee per operation? Linearizability? Read-your-writes? Causal?
- **Rate limits**: For services exposed to external callers, are inbound rate limits enforced? Can one caller saturate the system?
