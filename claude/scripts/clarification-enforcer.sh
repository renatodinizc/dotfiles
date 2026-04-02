#!/usr/bin/env zsh
# Clarification Enforcer — PreToolUse hook
# Reads state from protocol-router, blocks execution tools when clarification is needed.
#
# Input:  JSON via stdin (session_id, tool_name, tool_input)
# Output: JSON with permissionDecision "deny" when blocking, or silent exit 0
#
# Matcher in settings.json: Write|Edit|Bash|Agent|TaskCreate|NotebookEdit|Skill

set -uo pipefail

STATE_DIR="$HOME/.claude/hook-state"

# --- Read hook input ---
INPUT="$(cat)"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // "unknown"')"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // ""')"

STATE_FILE="$STATE_DIR/${SESSION_ID}.json"

# No state file = no enforcement
[[ ! -f "$STATE_FILE" ]] && exit 0

# Read state
TURN_STATE="$(jq -r '.turn_state // "clear"' "$STATE_FILE")"

# Clear state = allow everything
[[ "$TURN_STATE" != "needs_clarification" ]] && exit 0

# --- NEEDS_CLARIFICATION: block execution tools ---
# (Read-only tools are already excluded by the matcher in settings.json)

VAGUE_TERMS="$(jq -r '.vague_terms // [] | join(", ")' "$STATE_FILE")"
HAS_CONFLICT="$(jq -r '.has_conflict // false' "$STATE_FILE")"
CLAR_ROUND="$(jq -r '.clarification_round // 0' "$STATE_FILE")"

REASON="Clarification-First HARD CONSTRAINT active."
[[ -n "$VAGUE_TERMS" && "$VAGUE_TERMS" != "" ]] && REASON+=" Vague terms detected: [${VAGUE_TERMS}]."
[[ "$HAS_CONFLICT" == "true" ]] && REASON+=" Conflicting goals detected."
REASON+=" You MUST ask clarifying questions before using ${TOOL_NAME}."
REASON+=" Your first response must be clarifying questions -- this is enforced by hook."
REASON+=" (Clarification round ${CLAR_ROUND}/2)"

jq -n --arg reason "$REASON" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": $reason
  }
}'

exit 0
