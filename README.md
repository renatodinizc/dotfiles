# dotaifiles

Traditional dotfiles configure your shell. These configure how your AI thinks.

This is my [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) configuration. It replaces the default behavior (agreeable, verbose, conventional) with the behavior I actually want (critical, precise, opinionated). Every rule, skill, and hook exists because the default wasn't reliable enough for production work.

This is not a drop-in solution. It encodes how I work: backend systems, Rust, distributed architectures. Fork it and rewrite it for how you work. The value is in the approach, not the specifics.

## The Problem

Out of the box, AI coding assistants have three failure modes that compound:

1. **Sycophancy.** You say "I think we should use Redis here." The assistant says "Great idea! Here's how to set up Redis." It never asks whether you need Redis.
2. **Fabrication without disclosure.** They guess and present guesses as facts. They cite functions that don't exist, describe APIs from training-data recall, and build on assumptions about code they haven't read.
3. **Conventional defaults.** They reach for the most common approach, not the best one for the situation. The recommendations come from training-data frequency, not from analysis of your actual constraints.

Telling an AI to "be careful" or "be honest" doesn't fix these. Specific protocols with defined triggers, confidence thresholds, and verification procedures do.

## Architecture

Four layers, each with different reliability characteristics:

```
┌─────────────────────────────────────────────┐
│  Hooks        deterministic, 100% enforced  │  Shell scripts, regex matches
├─────────────────────────────────────────────┤
│  Rules        advisory, ~80% compliance     │  Always-on or context-triggered
├─────────────────────────────────────────────┤
│  Skills       auto-triggering workflows     │  Full procedures, loaded on demand
├─────────────────────────────────────────────┤
│  Agents       isolated subprocesses         │  Protected context, faster models
└─────────────────────────────────────────────┘
```

The distinction between hooks and rules is deliberate. Advisory rules fail roughly 20% of the time. For formatting and security, that's not acceptable. Hooks regex-match `rm -rf /`, `git push --force main`, `DROP TABLE`, and fork bombs, then block execution before it happens. No LLM reasoning in the loop, no compliance gap.

Skills auto-trigger based on context rather than requiring slash commands. A skill that activates invisibly when a YouTube URL appears is more powerful than one you have to remember to invoke, because it improves quality without requiring vigilance.

## What's Inside

### Intellectual Honesty Protocol

Not "be honest" (that doesn't work). A multi-tier system with specific triggers and a noise filter:

- **Tier 1 (silent):** Every response runs premise validation, consider-the-opposite, and bias scanning internally. The user sees nothing unless something material surfaces.
- **Tier 2 (nudges):** A 5-gate materiality filter (would this change the decision? is it large enough to matter? is it directional? is it irreversible? have I already flagged too much this session?) prevents noise. Max 1 flag per response.
- **Tier 3 (deep dive):** For irreversible decisions. Pre-mortem analysis, steelman of dismissed positions, falsifiability audits. Triggers on commitment language ("I've decided to...") or high-stakes domains.

Calibrated uncertainty with defined probability ranges ("likely" = 65-79%, "very likely" = 80-92%) paired with evidence quality ratings (high/medium/low). No vague hedging.

### Operational Discipline

How the AI verifies itself. Every factual claim tagged by origin: `[VERIFIED]` (confirmed via tool), `[DOC]` (from provided documents), `[KNOWLEDGE]` (training data, flagged explicitly), `[INFERENCE]` (deduction, reasoning chain shown). Spec-driven workflow: read existing code before generating. Verbosity treated as hidden uncertainty, not thoroughness.

### Context-Triggered Rules

Activate only when matching file types appear. No wasted tokens on irrelevant sessions.

| Rule | Activates on | Core questions |
|---|---|---|
| Feature Implementation | All code files | TDD workflow. Who consumes this? What happens at 2x load? At 100x? How do I know this is working in production (not "are errors logged?")? |
| Systems Thinking | Code + infrastructure | Does this push teams' technical directions toward or away from each other? Is an 80% migration worth 0% (new code adopts the old pattern)? Optimize before scaling. |
| Rust Engineering | `.rs`, `Cargo.toml` | Prefer `&T` over cloning. Never `unwrap()` in production. Never hold MutexGuard across `.await`. Timeout on every network call. |

Each rule encodes specific engineering judgment, not generic best practices. Generic advice is already in the training data. Rules that say "be careful with error handling" add nothing. Rules that say "use thiserror for libraries, anyhow for applications, map errors at module boundaries" change behavior.

### Skills

Only descriptions (~30 tokens each) load at startup. Full workflow loads on demand.

| Skill | What it does |
|---|---|
| `deep-dive` | Parallel multi-source research with source triangulation, credibility ratings, 2+ independent sources required for major claims |
| `code-review` | 5-phase review: scope the change type, investigate (trace consumers, read schemas), standard checks, staff-engineer questions ("what breaks at 100x?"), structured verdict |
| `steelman` | Builds the strongest case for the opposing position. Quality bar: passes the Ideological Turing Test |
| `pre-mortem` | Gary Klein failure analysis. Imagine it failed, work backward. Classify each failure as addressable, watchable, acceptable, or noise |
| `fetch-web` | Full JS rendering via Playwright MCP, with fallback chain (shot-scraper, lynx, curl) |
| `fetch-youtube` | Transcript and metadata extraction via yt-dlp |
| `fetch-social` | Instagram (instaloader) and Pinterest (gallery-dl) via dedicated CLI tools |

### Hooks

| Event | What it does |
|---|---|
| Session start | Detects Rust project, scans Cargo.toml for key dependencies (tokio, kafka, axum, gRPC, SQL, Redis...), flags multi-service projects |
| Before shell command | Regex-blocks destructive commands: `rm -rf /`, force push to main, `git reset --hard`, `DROP TABLE`, fork bombs |
| After file write | Auto-formats: rustfmt for `.rs`, prettier for `.ts/.js/.json/.css` |
| On completion | macOS notification with sound |

File protection (`.env`, secrets, credentials) is enforced through permission denials, not hooks.

### Agents

Specialized subprocesses for tasks that would bloat the main context window. Both run on faster models.

- **Researcher:** Deep investigation with source attribution. 2+ independent sources for major claims. Credibility-rated sources. Says "I could not find reliable information" when that's the case.
- **Debugger:** Root cause analysis. Read the error, reproduce, trace, hypothesize, test, fix, verify. Never guesses. Never applies multiple changes at once.

## Setup

```bash
git clone git@github.com:renatodinizc/dotaifiles.git
cd dotaifiles
cp .env.example .env  # Add your API keys
bash install.sh
```

Symlinks everything into `~/.claude/` and registers MCP servers. Run again after pulling updates.

```bash
brew install yt-dlp jq    # Required for YouTube and JSON processing
```

Node.js 18+ required for Playwright MCP.

## Structure

```
claude/
├── CLAUDE.md                        # Global instructions and thinking standards
├── settings.json                    # Hooks, MCP servers, permissions
├── agents/
│   ├── researcher.md                # Deep research with source attribution
│   └── debugger.md                  # Root cause analysis, never guesses
├── rules/
│   ├── intellectual-honesty.md      # Anti-sycophancy, calibrated reasoning
│   ├── operational-discipline.md    # Source tagging, verification, context hygiene
│   ├── feature-implementation.md    # TDD, blast radius, failure modes, observability
│   ├── systems-thinking.md          # Migrations, capacity, debt, architecture
│   └── rust-engineering.md          # Ownership, async, errors, distributed systems
├── scripts/
│   └── detect-project.sh            # SessionStart project detection
└── skills/
    ├── deep-dive/SKILL.md           # Multi-source research
    ├── code-review/SKILL.md         # 5-phase systematic review
    ├── steelman/SKILL.md            # Strongest opposing argument
    ├── pre-mortem/SKILL.md          # Gary Klein failure analysis
    ├── fetch-web/SKILL.md           # JS-rendered web fetching
    ├── fetch-youtube/SKILL.md       # YouTube transcript extraction
    └── fetch-social/SKILL.md       # Instagram/Pinterest fetching
```
