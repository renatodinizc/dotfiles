#!/usr/bin/env zsh
# Response Monitor — Stop hook
# Scans Claude's response for protocol violations. Blocks on violations to force revision.
#
# Input:  JSON via stdin (stop_hook_active, session_id, last_assistant_message?, transcript_path?)
# Output: JSON with decision "block" + reason when violations found, or silent exit 0
#
# CRITICAL: Must check stop_hook_active to prevent infinite loops.

set -uo pipefail

STATE_DIR="$HOME/.claude/hook-state"

# --- Read hook input ---
INPUT="$(cat)"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // "unknown"')"

# --- Infinite loop prevention ---
STOP_ACTIVE="$(echo "$INPUT" | jq -r '.stop_hook_active // false')"
if [[ "$STOP_ACTIVE" == "true" ]]; then
  exit 0
fi

# --- Get assistant's response ---
# Primary: last_assistant_message field (may not exist in all versions)
RESPONSE="$(echo "$INPUT" | jq -r '.last_assistant_message // ""')"

# Fallback: parse transcript file
if [[ -z "$RESPONSE" ]]; then
  TRANSCRIPT="$(echo "$INPUT" | jq -r '.transcript_path // ""')"
  if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
    # Extract last assistant message from JSONL transcript
    RESPONSE="$(tail -20 "$TRANSCRIPT" | jq -r 'select(.role == "assistant") | .content // ""' 2>/dev/null | tail -1)"
  fi
fi

# No response to check = allow
[[ -z "$RESPONSE" ]] && exit 0

typeset -a VIOLATIONS=()

# --- Check 1: Anti-Sycophancy ---
# Scan first 150 characters for sycophantic openers
OPENING="${RESPONSE:0:150}"
if echo "$OPENING" | grep -qiE "^(great (question|point|idea|thinking|observation)|excellent (question|point|observation|idea)|that's a (great|excellent|fantastic|wonderful|brilliant)|absolutely[!. ]|what a (great|wonderful|thoughtful)|love (this|that|it|the)|perfect[!. ]|brilliant[!. ]|amazing[!. ]|wonderful[!. ])"; then
  VIOLATIONS+=("Anti-sycophancy: response opens with flattery. Per IHP rules, start with substance, not affirmation.")
fi

# --- Check 2: Clarification Skip Detection ---
STATE_FILE="$STATE_DIR/${SESSION_ID}.json"
if [[ -f "$STATE_FILE" ]]; then
  TURN_STATE="$(jq -r '.turn_state // "clear"' "$STATE_FILE")"
  if [[ "$TURN_STATE" == "needs_clarification" ]]; then
    # Count question marks in the response
    QMARK_COUNT=$(echo "$RESPONSE" | tr -cd '?' | wc -c | tr -d ' ')
    if (( QMARK_COUNT < 2 )); then
      VIOLATIONS+=("Clarification-First: the user's prompt required clarification but your response has fewer than 2 questions. Ask clarifying questions before proceeding.")
    fi
  fi
fi

# --- Output ---
if (( ${#VIOLATIONS[@]} > 0 )); then
  REASON="Protocol violations detected. Please revise your response:\n"
  for v in "${VIOLATIONS[@]}"; do
    REASON+="- ${v}\n"
  done

  reason_text="$(echo -e "$REASON")"
  jq -n --arg reason "$reason_text" '{
    "decision": "block",
    "reason": $reason
  }'
fi

exit 0
