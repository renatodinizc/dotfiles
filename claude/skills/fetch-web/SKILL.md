---
name: fetch-web
description: Fetches web page content with full JavaScript rendering. Use when navigating to URLs, reading web pages, extracting web content, or when WebFetch returns incomplete/empty content. Prioritizes Playwright MCP with fallback to shot-scraper, lynx, and curl.
allowed-tools: Bash, Read, Write
---

# Web Fetching Protocol

Follow this priority order to maximize the chance of getting fully-rendered content.

## Priority 1: Playwright MCP (Default)

Always attempt the **Playwright MCP server** first. It provides full headless Chromium with JavaScript rendering.

Use Playwright MCP tools to:
- Navigate to URLs via `browser_navigate`
- Extract content via `browser_snapshot` (accessibility tree, preferred for text)
- Take screenshots via `browser_take_screenshot` when visual context is needed
- Interact with pages (click, scroll, fill forms) when necessary

Handles JS-rendered SPAs, bot protection, cookie consent walls, and dynamic content.

## Priority 2: `shot-scraper` (CLI Fallback with JS Rendering)

If Playwright MCP is unavailable or errors out:

```bash
shot-scraper html "URL"                                    # Rendered HTML
shot-scraper javascript "URL" "document.body.innerText"    # Text extraction
shot-scraper "URL" -o screenshot.png                       # Screenshot
```

Install if missing: `pip install shot-scraper && shot-scraper install`

## Priority 3: `lynx -dump` (Text-Only, No JS)

For server-rendered pages when the above fail:

```bash
lynx -dump "URL"
```

Install if missing: `brew install lynx`

## Priority 4: `curl` (Raw HTML, Last Resort)

Only for API endpoints or when all else fails:

```bash
curl -sL "URL"
```

## Rules

- **Never assume a page is static.** Default to Playwright MCP.
- If a tool is not installed, inform the user and offer to install it before falling back.
- When WebFetch returns incomplete/empty content, escalate to Playwright MCP.
