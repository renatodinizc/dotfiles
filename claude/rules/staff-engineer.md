---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/docker-compose.*"
  - "**/Dockerfile"
  - "**/*.proto"
---

# Staff Engineer Review Protocol

Before modifying code, run these checks. Skip items clearly irrelevant to the change.

## Pre-Change: Scope the Blast Radius

1. **Who consumes this?** List all direct consumers of the function, struct, message, or API being changed. If you cannot enumerate them, search before proceeding.
2. **What crosses a boundary?** If the change touches serialization, message formats, API contracts, or shared state, list all services/components on both sides of that boundary.
3. **What happens during rollout?** Will old and new versions coexist? Is the change backwards-compatible with in-flight messages/requests?

## Data Flow Tracing

Before modifying any message producer, consumer, or shared data structure:

1. Trace the data from **origin to final consumer**. Name each hop.
2. At each hop, state what happens if this hop **fails** (timeout, crash, corrupt data).
3. State whether the change is **backwards-compatible** with data already in the pipeline.
4. If the answer to any of these is unknown, read the relevant code or ask before proceeding.

## Failure Mode Checklist

For changes touching network, storage, or async coordination:

- What happens if the downstream service is **slow** (not down, slow)?
- What happens if this operation is **retried**? Is it idempotent?
- What happens if the process **crashes halfway** through this operation?
- What happens under **2x expected load**?
- Are errors **observable**? Will someone get paged, or will this fail silently?
