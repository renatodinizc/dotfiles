---
name: pre-mortem
description: Runs a pre-mortem analysis on a plan or decision using Gary Klein's method. Use when the user is about to commit to an irreversible or high-stakes decision, when asked to stress-test a plan, or when commitment language appears ("I've decided to", "I'm going to", "I accepted").
disable-model-invocation: true
allowed-tools: Read
---

# Pre-Mortem Protocol (Gary Klein)

Imagine the plan has failed, then work backward to identify why.

## Setup

> "It is 12 months from now. You went with [decision]. It didn't work out — not a catastrophe, but clearly a failure by your own standards. What went wrong?"

## Process

### 1. Let the User Go First
Ask the user to generate their own failure reasons before adding yours. Their blind spots are the valuable signal.

### 2. Add Non-Obvious Failures
Contribute 2-3 failure modes the user likely hasn't considered:
- External/market shifts
- Second-order consequences
- Psychological/motivational risks (burnout, loss of interest, identity mismatch)
- Dependency failures (things outside their control)

### 3. Cap and Classify
Total failure modes: 5-7 maximum. More than that is noise.

Classify each as:
- **Addressable**: Can act now to prevent. Name the specific mitigation.
- **Watchable**: Define the early warning sign and the decision point to reconsider.
- **Acceptable**: Willing to bear this risk. Name it explicitly.
- **Noise**: Catastrophizing. Discard explicitly with reasoning.

### 4. Rank
Order by: (likelihood) x (severity) x (irreversibility). The top 2-3 deserve concrete action plans.

### 5. Flip It
Always end on the positive case:
> "Now let's flip it — if this goes really well, what happened? What was the non-obvious thing that made the difference?"

### 6. Pre-Mortem Inaction (if applicable)
If the alternative is meaningful:
> "What does failure look like if you DON'T do this? What's the cost of inaction?"

## When NOT to Use
- User is catastrophizing (pre-mortem amplifies anxiety)
- Decision is already executed (shift to support mode)
- User needs courage, not analysis
- Hypothetical/exploratory context ("what if...")
