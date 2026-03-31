---
paths:
  - "**/*.rs"
  - "**/*.py"
  - "**/*.ts"
  - "**/*.go"
  - "**/*.java"
  - "**/*.kt"
  - "**/Cargo.toml"
  - "**/docker-compose.*"
  - "**/Dockerfile"
  - "**/*.proto"
---

# Systems Thinking Protocol

For design discussions, architecture decisions, and cross-cutting concerns. Not about individual code changes but about whether we're building the right thing the right way.

## Design Review

- **Vector alignment**: Does this proposal push teams' technical directions toward or away from each other? A locally correct decision that fragments the broader architecture is net negative.
- **Non-goal sharpness**: What is explicitly out of scope? If you can't articulate non-goals, scope will creep.
- **"I wouldn't start from here"**: The design may be correct in a vacuum but unreachable from the actual current state. What is the realistic path from where the system is today?
- **Consistency per operation**: "Strong consistency" is not a specification. What does each operation actually need? Linearizability? Read-your-writes? Causal? Specify per operation, not per system.

## Migrations

- **10x threshold**: Has the system grown (or will it grow) by 10x? If not, migration cost likely exceeds benefit. If yes, migration is probably the only scalable fix.
- **Hardest case first**: Validate with the most atypical consumer first. Easy early success creates false confidence.
- **Expand-Contract**: Three phases, no shortcuts. Expand (support old + new), migrate (move consumers), contract (remove old).
- **Stop the bleeding**: Block the old pattern via linter or CI before removing it. Otherwise new code adopts the old pattern while you're migrating.
- **Reversibility**: Can any team immediately roll back their part? If the migration is irreversible by design, the risk profile is fundamentally different.
- **Incomplete migration = 0% done**: An 80% migration with no enforcement will regress. New code adopts the old pattern. 100% requires the migration team's direct effort.

## Capacity and Scaling

- **Optimize before you scale**: A 10x query optimization defers the scaling investment entirely. Profile the bottleneck before adding hardware.
- **Plan for peak, not average**: Averages hide spikes. Plan for 2-5x average to handle surges. Verify graceful degradation at the threshold, not hard failure.
- **Quality before decomposition**: Extracting services before defining clean internal boundaries moves coupling from function calls to network calls. The coupling survives the decomposition.
- **Rate limit and attribution**: For any system exposed to external callers, can you identify each caller and enforce per-caller limits? Without this, one misbehaving caller saturates the system.

## Technical Debt

- **Hotspot concentration**: Where did 80% of the failures actually come from? If it's one file or one service, a targeted fix there outperforms a new process applied everywhere. Systemic process is expensive and resisted; hotspot fixes are cheap and focused.
- **Debt compounds at interfaces**: Debt in interfaces, state management, and data models compounds with every consumer. Debt in leaf-node implementation code does not. Prioritize accordingly.
- **Debt classification**: Does this debt slow down all future changes in this area, or is it isolated? Only the former is urgent.
- **Engineering strategy as debt prevention**: A locally correct decision that contradicts established patterns creates debt the moment it ships. Check alignment with the existing technical direction before approving.
