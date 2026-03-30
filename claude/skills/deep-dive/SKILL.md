---
name: deep-dive
description: Conducts deep, multi-source research on a topic with parallel searches, source triangulation, and structured synthesis. Use when asked to research, investigate, or deeply understand a topic, or when a question requires current information from multiple sources.
allowed-tools: Bash, Read, Write, WebSearch, WebFetch, Grep, Glob, Agent
---

# Deep Dive Research Protocol

Systematic research pipeline for producing reliable, well-sourced analysis.

## Phase 1: Scope

Before searching, define:
- **Core question**: What specifically needs to be answered?
- **Boundaries**: What is in scope and out of scope?
- **Output format**: Summary, comparison table, recommendation, or raw findings?

State these explicitly before proceeding.

## Phase 2: Search Strategy

Plan 3-5 diverse search angles:
- Direct keyword searches for the core topic
- Adjacent/related searches that might surface non-obvious findings
- Contrarian searches (arguments against, criticisms, failures)
- Recency-filtered searches for current state

## Phase 3: Parallel Retrieval

Launch multiple search agents in parallel to maximize coverage and speed:
- Each agent covers a different search angle
- Each returns structured findings with source URLs
- Target 8-15 distinct sources minimum

## Phase 4: Triangulation

For each key finding:
- Require confirmation from at least 2 independent sources for major claims
- Flag single-source claims explicitly
- Rate source credibility: official docs > academic papers > reputable publications > blog posts > social media
- Note contradictions between sources rather than silently picking one

## Phase 5: Synthesis

Structure the output as:
1. **Executive summary** (3-5 sentences answering the core question)
2. **Key findings** (bulleted, each with source attribution)
3. **Contradictions and open questions** (where sources disagree)
4. **Confidence assessment** (what is well-established vs. uncertain)
5. **Sources** (numbered list with URLs)

## Rules

- Never present a single source's claim as established fact.
- Distinguish between widely-confirmed findings and emerging/contested claims.
- Include the strongest counterargument to the main conclusion.
- If the topic has changed recently, note the date sensitivity.
- Prefer primary sources over summaries of summaries.
