---
name: deep-dive
description: Conducts deep, multi-source research on a topic with parallel searches, source triangulation, and structured synthesis. Use when asked to research, investigate, or deeply understand a topic, or when a question requires current information from multiple sources.
allowed-tools: Bash, Read, WebSearch, WebFetch, Grep, Glob, Agent, mcp__tavily__tavily_search, mcp__tavily__tavily_research, mcp__tavily__tavily_extract, mcp__tavily__tavily_crawl, mcp__tavily__tavily_map
---

# Deep Dive Research Protocol

Systematic research pipeline for producing reliable, well-sourced analysis.

## Research Intensity

Two modes. Select based on the user's request.

**Standard** (default): Cost-efficient, good for most research. Uses `tavily_search` with `search_depth: "basic"` and default `max_results`. Appropriate when the user asks to "look into", "find out about", or "research" something without emphasis on depth.

**Thorough**: Full pipeline, higher API usage. Triggered when the user signals they want depth: "deep dive", "thorough", "exhaustive", "comprehensive", "top-notch", "leave no stone unturned", or similar. Uses:
- `tavily_research` with `model: "pro"` as the research backbone
- `tavily_search` with `search_depth: "advanced"`, `max_results: 20`, and `include_raw_content: true` for specific angles
- `tavily_extract` to pull full content from the most important sources found
- `tavily_crawl` when a specific site needs deep exploration (documentation, technical specs)
- Target 15-25 distinct sources minimum (vs. 8-15 for standard)

When in doubt about which mode, default to standard. If the results feel thin, escalate to thorough and tell the user you're doing so.

## Phase 1: Scope

Before searching, define:
- **Core question**: What specifically needs to be answered?
- **Boundaries**: What is in scope and out of scope?
- **Output format**: Summary, comparison table, recommendation, or raw findings?
- **Intensity**: Standard or thorough? (based on user's language)

State these explicitly before proceeding.

## Phase 2: Search Strategy

Plan 3-5 diverse search angles (4-6 for thorough mode):
- Direct keyword searches for the core topic
- Adjacent/related searches that might surface non-obvious findings
- Contrarian searches (arguments against, criticisms, failures)
- Recency-filtered searches for current state (use `time_range` or `start_date`/`end_date` parameters)
- Domain-specific searches (use `include_domains` to target official docs, academic sources, or known-quality sites)

### Thorough mode additions
- Use `tavily_research` (pro) first to get a broad foundation, then run targeted `tavily_search` (advanced) queries to fill gaps and verify claims
- Use `tavily_map` to discover the structure of key sites before crawling specific sections
- Use `tavily_extract` (advanced) on the most authoritative sources for full content

## Phase 3: Parallel Retrieval

Launch multiple researcher subagents in parallel to maximize coverage and speed. Researcher agents handle source credibility, triangulation, and structured output.
- Each agent covers a different search angle
- Each returns structured findings with source URLs
- Standard: target 8-15 distinct sources
- Thorough: target 15-25 distinct sources, use `tavily_extract` to get full content from the top 5-10 most relevant results

## Phase 4: Triangulation

For each key finding:
- Require confirmation from at least 2 independent sources for major claims
- Flag single-source claims explicitly
- Rate source credibility: official docs > academic papers > reputable publications > blog posts > social media
- Note contradictions between sources rather than silently picking one

In thorough mode: extract and cross-reference specific claims from raw page content rather than relying on search snippets alone.

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
- Use `tavily_search` over generic `WebSearch` when Tavily is available. It provides better control over search depth, date ranges, and domain filtering.
