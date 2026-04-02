---
name: systems-review
description: Structured review for design discussions, architecture decisions, and cross-cutting concerns. Use when evaluating whether we're building the right thing the right way.
user_invocable: true
---

# Systems Thinking Review

Apply these lenses to the design or architecture under discussion.

## Design Review

- **Vector alignment**: Does this proposal push teams' technical directions toward or away from each other? A locally correct decision that fragments the broader architecture is net negative.
- **Non-goal sharpness**: What is explicitly out of scope? If you can't articulate non-goals, scope will creep.
- **"I wouldn't start from here"**: The design may be correct in a vacuum but unreachable from the actual current state. What is the realistic path from where the system is today?
- **Consistency per operation**: "Strong consistency" is not a specification. What does each operation actually need? Linearizability? Read-your-writes? Causal? Specify per operation, not per system.

## Migrations

- **10x threshold**: Has the system grown (or will it grow) by 10x? If not, migration cost likely exceeds benefit.
- **Hardest case first**: Validate with the most atypical consumer first. Easy early success creates false confidence.
- **Expand-Contract**: Three phases, no shortcuts. Expand (support old + new), migrate (move consumers), contract (remove old).
- **Stop the bleeding**: Block the old pattern via linter or CI before removing it.
- **Reversibility**: Can any team immediately roll back their part?
- **Incomplete migration = 0% done**: An 80% migration with no enforcement will regress.

## Capacity and Scaling

- **Optimize before you scale**: A 10x query optimization defers the scaling investment entirely.
- **Plan for peak, not average**: Plan for 2-5x average to handle surges. Verify graceful degradation at the threshold.
- **Quality before decomposition**: Extracting services before defining clean internal boundaries moves coupling from function calls to network calls.
- **Rate limit and attribution**: Can you identify each caller and enforce per-caller limits?

## Technical Debt

- **Hotspot concentration**: Where did 80% of the failures actually come from? Targeted fix > systemic process.
- **Debt compounds at interfaces**: Debt in interfaces, state management, and data models compounds with every consumer. Leaf-node debt does not.
- **Debt classification**: Does this debt slow down all future changes in this area, or is it isolated? Only the former is urgent.
- **Engineering strategy as debt prevention**: A locally correct decision that contradicts established patterns creates debt the moment it ships.
