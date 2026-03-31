# dotaifiles

Personal AI dotfiles. Traditional dotfiles configure your shell and editor. These configure how your AI reasons, verifies, and operates.

## Why

AI assistants are capable but unreliable by default. They agree when they should challenge. They guess when they should verify. They default to conventional approaches when more powerful ones exist. They forget your standards between sessions.

These dotfiles fix that. Not through vague instructions ("be careful", "be honest") but through specific protocols with defined triggers, confidence thresholds, and verification procedures.

## Core Protocols (Always Active)

### Intellectual Honesty Protocol

Governs how the AI *reasons*. Anti-sycophancy is the baseline, not a feature.

- No opening affirmations. User claims treated as hypotheses to evaluate, not facts to incorporate. Ground held under pressure.
- Three-tier challenge system: silent internal checks on every response, labeled nudges (`[Consider]`, `[Challenge]`, `[Red Flag]`) when something material passes a 5-gate filter, and deep-dive protocols (pre-mortem, steelman, falsifiability audit) for irreversible decisions.
- Calibrated uncertainty with explicit probability ranges ("likely" = 65-79%, "very likely" = 80-92%) paired with evidence quality ratings (high/medium/low). No vague hedging.
- Emotional context detection. Validates before analyzing. Never pushes frameworks when you need to be heard.

### Operational Discipline

Governs how the AI *verifies itself*. Procedural fact-checking, not good intentions.

- Source provenance tagging: every claim tagged as `[VERIFIED]`, `[DOC]`, `[KNOWLEDGE]`, or `[INFERENCE]`. Training-data claims flagged explicitly.
- Spec-driven workflow: read existing code and docs before generating. Never generate from training-data patterns when a source of truth exists.
- Verbosity detection: wordiness treated as a signal of hidden uncertainty, not thoroughness.
- Context hygiene with three-tier fidelity (FULL/COMPRESSED/STUB) for what survives context compaction, plus post-compaction recovery checks.

## Domain Rules (Context-Triggered)

Activate only when working on matching file types. Narrow by design.

**Staff Engineer Protocol** (Rust, Dockerfile, Protobuf): Pre-change blast radius scoping, data flow tracing (origin to final consumer, failure mode at each hop), failure checklist (slow downstream, retries, crashes, 2x and 100x load), and an observability checklist (metrics, dashboards, alerts, deployment validation). Not "are errors logged?" but "how do I know this feature is working correctly in production?"

**Test-First Workflow** (all code files): Red/green TDD as the default. Run existing tests first when entering a codebase. Write a failing test before implementing. Convert manual testing discoveries into automated tests. Match existing test style.

**Rust Engineering** (`.rs`, `Cargo.toml`): Ownership patterns (prefer `&T` over cloning, `Cow<'_, str>` for maybe-allocating), error handling conventions (thiserror for libraries, anyhow for applications, never `unwrap()` in production), async discipline (tokio-specific, cancel-safe `select!`, never hold MutexGuard across `.await`), and a distributed systems checklist (timeout on every network call, exponential backoff + jitter, idempotency, graceful shutdown, circuit breakers).

## Skills (Auto-Triggering Workflows)

Only descriptions (~30 tokens each) load at startup. Full workflow loads on demand, keeping context lean.

| Skill | Triggers when... | What it does |
|---|---|---|
| **deep-dive** | Asked to research a topic | Parallel multi-source search, triangulation, structured synthesis |
| **steelman** | Taking a strong position or dismissing an alternative | Builds the strongest case for the opposing view (Ideological Turing Test) |
| **code-review** | Reviewing a PR or changes | Systematic: correctness, security, performance, design. No style nitpicks. |
| **pre-mortem** | High-stakes decision | Gary Klein failure analysis: imagine it failed, work backward |
| **fetch-web** | A URL needs reading | Playwright MCP (full JS) with fallback chain: shot-scraper, lynx, curl |
| **fetch-youtube** | YouTube link appears | Transcript + metadata extraction via yt-dlp |
| **fetch-social** | Instagram/Pinterest URL | Dedicated CLI tools that bypass authentication walls |

Skills that auto-trigger are more powerful than slash commands you have to remember. They improve quality invisibly.

## Hooks (Deterministic Guardrails)

Rules are advisory (~80% compliance). Hooks execute 100% of the time.

- **SessionStart**: Detects project type from Cargo.toml, scans dependencies (tokio, kafka, axum, gRPC, SQL, Redis, etc.), flags multi-service projects. Injects relevant context before you start working.
- **Dangerous command blocker**: Regex-matches and blocks `rm -rf /`, `git push --force main`, `git reset --hard`, `DROP TABLE`, and fork bombs before execution.
- **Auto-formatting**: Runs rustfmt on `.rs` files and prettier on `.ts/.js/.json/.css` after every file write. Formatting is a hook, not a conversation.
- **File protection**: Denies reads on `.env`, secrets, and credential files. Prevents accidental leakage.
- **Notifications**: macOS alerts when tasks complete or need attention.

## Agents (Subprocesses)

Specialized subprocesses for tasks that would bloat the main context window. Both run on faster models to keep costs down.

- **Researcher**: Deep investigation with source attribution, credibility-rated sources, 2+ independent sources required for major claims.
- **Debugger**: Root cause analysis. Read error, reproduce, trace, hypothesize, test, fix, verify. Never guesses, never applies multiple changes at once.

## Setup

```bash
git clone git@github.com:renatodinizc/dotaifiles.git
cd dotaifiles
cp .env.example .env  # Add your API keys
bash install.sh
```

Symlinks everything into `~/.claude/` and registers MCP servers. Run again after pulling updates.

### Dependencies

```bash
brew install yt-dlp jq
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
├── rules/                           # Always-on and context-triggered protocols
│   ├── intellectual-honesty.md      # Anti-sycophancy, calibrated reasoning
│   ├── operational-discipline.md    # Source tagging, context hygiene, verification
│   ├── staff-engineer.md            # Blast radius, data flow, failure modes, observability
│   ├── test-first.md                # TDD as default, red/green cycle, test harness discovery
│   └── rust-engineering.md          # Ownership, async, errors, distributed systems
├── scripts/
│   └── detect-project.sh            # SessionStart: project type + dependency detection
└── skills/                          # Auto-triggering workflows
    ├── deep-dive/SKILL.md
    ├── steelman/SKILL.md
    ├── code-review/SKILL.md
    ├── pre-mortem/SKILL.md
    ├── fetch-web/SKILL.md
    ├── fetch-youtube/SKILL.md
    └── fetch-social/SKILL.md
```

## Philosophy

The best dotfiles encode how you think, not just what tools you use. A `.gitconfig` that sets `rebase.autosquash=true` says something about how you approach version control. An AI rule that says "treat user claims as hypotheses" says something about how you approach truth.

These dotfiles encode a specific stance: AI should be a thinking partner that makes you more rigorous, not a yes-man that makes you feel productive. Every rule, skill, and hook exists because the default behavior was not reliable enough.

This is a personal configuration. It reflects how I work: backend systems, Rust, distributed architectures. Fork it and make it yours.
