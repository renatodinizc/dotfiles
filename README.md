# dotfiles

Personal Claude Code configuration. Symlinks into `~/.claude/` via `install.sh`.

## Setup

```bash
git clone git@github.com:renatodinizc/dotfiles.git
cd dotfiles
cp .env.example .env  # Add your API keys
bash install.sh
```

## Structure

```
claude/
├── CLAUDE.md                          # Global instructions
├── settings.json                      # Hooks, security, MCP servers
├── agents/
│   ├── researcher.md                  # Deep research with source attribution
│   └── debugger.md                    # Root cause analysis
├── rules/                             # Always-on behavioral guidance
│   ├── intellectual-honesty.md        # Anti-sycophancy, calibrated reasoning
│   ├── verification-protocol.md       # Confidence gates, source tagging, fact-checking
│   └── context-management.md          # Compaction, session discipline
└── skills/                            # Auto-triggering workflows
    ├── fetch-web/SKILL.md             # Playwright MCP with fallback chain
    ├── fetch-youtube/SKILL.md         # yt-dlp transcript extraction
    ├── fetch-social/SKILL.md          # Instagram (instaloader) + Pinterest (gallery-dl)
    ├── deep-dive/SKILL.md             # Multi-source research pipeline
    ├── steelman/SKILL.md              # Strongest case for opposing positions
    ├── code-review/SKILL.md           # Systematic bug/security/performance review
    └── pre-mortem/SKILL.md            # Gary Klein failure analysis (/pre-mortem)
```

## What it does

**Rules** load into every session and shape how Claude behaves: honest, verified, context-aware.

**Skills** auto-activate when Claude recognizes the right situation (e.g., fetching a YouTube URL triggers `fetch-youtube`). Only descriptions load at startup; full workflows load on demand.

**Agents** are specialized subprocesses (researcher, debugger) that run on Sonnet to protect the main context window.

**Settings** include security hooks (blocks `rm -rf /`, `git push --force main`, etc.), macOS notifications, and Playwright MCP with a persistent browser profile.

## API Keys

The `.env` file (gitignored) holds API keys for MCP servers. See `.env.example` for required keys.

Currently configured:
- **Tavily** (tavily.com) — AI-optimized web search, 1,000 free searches/month

## Dependencies

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — `brew install yt-dlp`
- [jq](https://jqlang.github.io/jq/) — `brew install jq`
- Node.js 18+ (for Playwright MCP via npx)
