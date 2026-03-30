---
name: fetch-youtube
description: Extracts transcripts and metadata from YouTube videos using yt-dlp. Use when a YouTube URL appears, the user asks to analyze a video, or research surfaces YouTube links. Never downloads video/audio files.
allowed-tools: Bash, Read
---

# YouTube Content Fetching

Claude cannot access YouTube content via WebFetch or Playwright. Use `yt-dlp` to extract transcripts and metadata.

## Extract Transcript

```bash
yt-dlp --write-subs --write-auto-subs --sub-langs "en" --skip-download \
  -o "/tmp/yt-%(id)s/%(id)s.%(ext)s" "VIDEO_URL"
```

Then read the resulting `.vtt` file. Strip VTT timing metadata and deduplicate overlapping cue text when presenting to the user.

### Subtitle language priority
1. `en` — English manual subtitles (most accurate)
2. `en-orig` — Original English auto-generated
3. `en.*` — Any English variant (broad fallback)
4. For non-English content, match the video's language or use `--sub-langs "LANG,en"`

## Extract Metadata

```bash
yt-dlp --dump-json --skip-download "VIDEO_URL"
```

Returns JSON with `title`, `description`, `duration`, `channel`, `upload_date`, `view_count`, `tags`, `chapters`.

## Quick Reference

| Need | Command |
|---|---|
| Transcript | `yt-dlp --write-subs --write-auto-subs --sub-langs "en" --skip-download -o "/tmp/yt-%(id)s/%(id)s.%(ext)s" "URL"` |
| Metadata | `yt-dlp --dump-json --skip-download "URL"` |
| List subs | `yt-dlp --list-subs --skip-download "URL"` |

## Rules

- Always use `--skip-download`. Never download video/audio unless the user explicitly asks.
- Clean up `/tmp/yt-*` files after reading.
- For playlists, add `--no-playlist` unless the user wants the full playlist.
- If no subtitles available, inform the user.
- Install if missing: `brew install yt-dlp`
