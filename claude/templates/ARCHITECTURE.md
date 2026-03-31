# Architecture

<!-- Copy this template into your project root and fill it in.
     Claude reads this file when the SessionStart hook or staff-engineer rule
     directs it to. Keep it under 80 lines so it stays useful, not bloated. -->

## Overview

<!-- 1-3 sentences: what does this system do and for whom? -->

## Components

<!-- List each service/binary/crate and its responsibility. One line each. -->

| Component | Responsibility | Owns |
|-----------|---------------|------|
| | | |

## Data Flow

<!-- Trace the primary data path from ingress to final state.
     Name each hop and the transport between them. -->

```
[Source] --protocol--> [Service A] --transport--> [Service B] --transport--> [Storage]
```

## Failure Domains

<!-- Which components can fail independently? What is the blast radius of each? -->

| Component | Failure Impact | Mitigation |
|-----------|---------------|------------|
| | | |

## Key Invariants

<!-- List the things that must always be true for this system to be correct.
     Examples: "every order is processed exactly once", "writes are durable before ack" -->

1.

## External Dependencies

<!-- Services, APIs, or infrastructure outside this repo that this system depends on. -->

| Dependency | What For | Timeout | Retry Strategy |
|-----------|----------|---------|----------------|
| | | | |
