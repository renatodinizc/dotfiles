#!/usr/bin/env bash
# Dangerous Command Guard — PreToolUse hook (Bash matcher)
# Blocks catastrophically destructive commands before execution.
#
# Input:  JSON via stdin (tool_input.command)
# Output: stderr message + exit 2 on block, silent exit 0 on allow

set -uo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command')

# Patterns: rm -rf dangerous paths, force-push to main, hard reset,
# DROP TABLE, chmod 777 on root, fork bombs
if echo "$CMD" | grep -qE \
  'rm\s+-rf\s+(/|~|\.|[*])|git\s+push\s+(-f|--force)\s+(origin\s+)?main|git\s+reset\s+--hard|DROP\s+TABLE|chmod\s+(-R\s+)?777\s+/|:()\{\s*:\|:&\s*\};:'; then
  echo "BLOCKED: Dangerous command detected: $CMD" >&2
  exit 2
fi
