# dotfiles

Dotfiles for the AI era.

Traditional dotfiles configure your shell, editor, and git to work the way you think. These dotfiles configure your AI. The goal is the same: reliability through configuration, not through hoping the tool behaves correctly.

## The Problem

AI assistants are capable but unreliable by default. They agree when they should challenge. They guess when they should verify. They default to conventional approaches when more powerful ones exist. They forget your standards between sessions.

These dotfiles fix that through two core protocols, a set of auto-triggering skills, and deterministic safety hooks.

## Two Core Protocols

The foundation is two complementary protocols that are always active in every session.

### Intellectual Honesty Protocol

Governs how the AI *reasons*. Anti-sycophancy is the baseline, not a feature.

- No opening affirmations. No "Great question!". Start with substance.
- Treat user claims as hypotheses to evaluate, not facts to incorporate.
- Hold ground under pressure. Only update when presented with new evidence.
- Calibrated uncertainty with explicit probability ranges, not vague hedging.
- Three-tier challenge system: silent internal checks on every response, labeled nudges when something material is off, and full deep-dive protocols (pre-mortem, steelman, falsifiability audit) for irreversible decisions.
- Emotional context detection. Validates before analyzing. Never pushes frameworks when you need to be heard.

### Verification Protocol

Governs how the AI *checks itself*. Procedural fact-checking, not just good intentions.

- Confidence-gated execution: below 70% confidence, stop and ask rather than guess.
- Source provenance tagging: every claim tagged as verified, from a document, from training data, or inferred. Training-data claims flagged explicitly.
- Quote-first analysis: extract evidence before reasoning, not after.
- Post-draft verification: review each claim, find the supporting source, remove anything unsupported.
- Spec-driven workflow: read existing code and docs before generating. Never generate from memory when a source of truth exists.
- Verbosity detection: wordiness is treated as a signal of hidden uncertainty, not thoroughness.

Together, these protocols mean the AI challenges your reasoning when it should, admits uncertainty when it exists, and verifies its own output before presenting it.

## Skills

Skills are encapsulated workflows that auto-activate when the AI recognizes the right situation. Only their descriptions (~30 tokens each) load at startup. The full workflow loads on demand, keeping context lean.

| Skill | Triggers when... | What it does |
|---|---|---|
| **fetch-web** | A URL needs to be read | Playwright MCP (full JS rendering) with fallback to shot-scraper, lynx, curl |
| **fetch-youtube** | A YouTube link appears | Extracts transcripts and metadata via yt-dlp. No video downloads. |
| **fetch-social** | Instagram or Pinterest URL | Uses instaloader / gallery-dl to bypass authentication walls |
| **deep-dive** | Asked to research a topic | Parallel multi-source search, source triangulation, structured synthesis |
| **steelman** | Taking a strong position or dismissing an alternative | Builds the strongest possible case for the opposing view |
| **code-review** | Reviewing a PR or code changes | Systematic check for bugs, security, performance, design. Skips style nitpicks. |
| **pre-mortem** | You invoke `/pre-mortem` | Gary Klein failure analysis: imagine the plan failed, work backward to find why |

The key insight: skills that auto-trigger are fundamentally more powerful than slash commands you have to remember to invoke. They improve quality invisibly. The fetching skills mean the AI always uses the right tool for the right content source. The steelman skill means opposing views are constructed at their strongest, not dismissed as strawmen.

## Agents, Hooks, and Settings

**Agents** are specialized subprocesses for tasks that would bloat the main context window. A researcher agent handles deep investigation with source attribution. A debugger agent traces root causes methodically. Both run on faster models to keep costs down.

**Hooks** are deterministic guardrails. Rules are advisory (~80% compliance). Hooks execute 100% of the time.
- Dangerous command blocker: prevents `rm -rf /`, `git push --force main`, `git reset --hard`, `DROP TABLE`, and fork bombs.
- File protection: denies reads on `.env`, secrets, and credential files.
- macOS notifications: sound alerts when tasks complete or need attention.

**MCP Servers** extend what the AI can access:
- Playwright (headless Chromium with persistent login sessions)
- Tavily (AI-optimized web search)

## Setup

```bash
git clone git@github.com:renatodinizc/dotfiles.git
cd dotfiles
cp .env.example .env  # Add your API keys (see .env.example for links)
bash install.sh
```

The install script symlinks everything into `~/.claude/` and registers MCP servers from your `.env` file. Run it again after pulling updates.

### Dependencies

```bash
brew install yt-dlp jq
```

Node.js 18+ required for Playwright MCP.

## Structure

```
claude/
├── CLAUDE.md                        # Global instructions and thinking standards
├── settings.json                    # Hooks, security, MCP servers, permissions
├── agents/
│   ├── researcher.md                # Deep research with source attribution
│   └── debugger.md                  # Root cause analysis, never guesses
├── rules/                           # Always-on protocols
│   ├── intellectual-honesty.md      # Anti-sycophancy, calibrated reasoning
│   ├── verification-protocol.md     # Confidence gates, source tagging
│   └── context-management.md        # Compaction, session discipline
└── skills/                          # Auto-triggering workflows
    ├── fetch-web/SKILL.md
    ├── fetch-youtube/SKILL.md
    ├── fetch-social/SKILL.md
    ├── deep-dive/SKILL.md
    ├── steelman/SKILL.md
    ├── code-review/SKILL.md
    └── pre-mortem/SKILL.md
```

## Philosophy

The best dotfiles encode how you think, not just what tools you use. A `.gitconfig` that sets `rebase.autosquash=true` says something about how you approach version control. An AI rule that says "treat user claims as hypotheses" says something about how you approach truth.

These dotfiles encode a specific stance: AI should be a thinking partner that makes you more rigorous, not a yes-man that makes you feel productive. Every rule, skill, and hook exists because the default behavior was not reliable enough.
