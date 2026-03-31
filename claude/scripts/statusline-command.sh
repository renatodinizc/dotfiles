#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dir=$(basename "$cwd")

branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

parts=()

if [ -n "$branch" ]; then
  parts+=("$(printf '\033[36m%s\033[0m' "$dir") $(printf '\033[34mgit:(\033[0m\033[31m%s\033[0m\033[34m)\033[0m' "$branch")")
else
  parts+=("$(printf '\033[36m%s\033[0m' "$dir")")
fi

if [ -n "$remaining" ]; then
  parts+=("$(printf '\033[33mctx:%s%%\033[0m' "$(printf '%.0f' "$remaining")")")
fi

printf '%s' "${parts[*]}"
