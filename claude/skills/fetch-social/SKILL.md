---
name: fetch-social
description: Fetches content from Instagram and Pinterest using dedicated CLI tools. Use when a user shares an Instagram or Pinterest URL, asks to analyze social media content, or needs to download posts/pins/boards. Standard web tools fail on these sites.
allowed-tools: Bash, Read, Write
---

# Social Media Content Fetching

Standard web tools (including Playwright) cannot reliably access Instagram and Pinterest due to authentication walls and bot detection. Use dedicated CLI tools.

## Instagram — `instaloader`

```bash
instaloader PROFILE_NAME                                          # All posts
instaloader -- -SHORTCODE                                         # Specific post
instaloader --reels PROFILE_NAME                                  # Reels
instaloader --stories --login USERNAME PROFILE_NAME               # Stories (login required)
instaloader --highlights --login USERNAME PROFILE_NAME            # Highlights (login required)
instaloader --no-posts --profile-pic PROFILE_NAME                 # Profile picture only
instaloader --no-pictures --no-videos --no-video-thumbnails PROFILE_NAME  # Metadata/captions only
```

- Public profiles work without login
- Stories/highlights/private profiles require `--login USERNAME`
- Install if missing: `pip install instaloader`

## Pinterest — `gallery-dl`

```bash
gallery-dl "https://www.pinterest.com/pin/PIN_ID/"               # Single pin
gallery-dl "https://www.pinterest.com/USER/BOARD_NAME/"           # Entire board
gallery-dl "https://www.pinterest.com/USER/"                      # All boards
gallery-dl -d ./output "URL"                                      # Custom output dir
gallery-dl --cookies-from-browser firefox "URL"                   # Private boards
```

- Most content accessible without auth
- Private boards require `--cookies-from-browser firefox` (or chrome, safari)
- Install if missing: `brew install gallery-dl` or `pip install -U gallery-dl`

## Fallback: `gallery-dl` for Instagram

If `instaloader` fails: `gallery-dl --cookies-from-browser firefox "INSTAGRAM_URL"`

## Workflow

1. Check if tool is installed (`which instaloader` or `which gallery-dl`)
2. If not, offer to install
3. Download to `/tmp/` or a temporary location
4. Read/analyze downloaded files
5. Clean up unless user wants to keep them

**Do NOT use WebFetch, curl, or Playwright for Instagram/Pinterest.**
