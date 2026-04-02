#!/usr/bin/env zsh
# Protocol Router — UserPromptSubmit hook
# Scores user messages against protocol patterns, writes state, injects activation XML.
#
# Input:  JSON via stdin (hook_event_name, prompt, session_id)
# Output: JSON with hookSpecificOutput.additionalContext (protocol-activation XML)
# Side effect: writes state to ~/.claude/hook-state/<session_id>.json

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
PATTERNS_FILE="$SCRIPT_DIR/protocol-patterns.conf"
STATE_DIR="$HOME/.claude/hook-state"
mkdir -p "$STATE_DIR"

# --- Configuration (edit protocol-patterns.conf, not here) ---
typeset -A THRESHOLDS=([EMOTIONAL]=4 [TIER3]=6 [CLAR]=5)
typeset -a PRIORITY_ORDER=(EMOTIONAL CLAR TIER3)

# --- Read hook input (single jq call) ---
INPUT="$(cat)"
eval "$(echo "$INPUT" | jq -r '@sh "PROMPT=\(.prompt // "") SESSION_ID=\(.session_id // "unknown")"')"

# Early exit on empty prompt
[[ -z "$PROMPT" ]] && exit 0

# --- Phase 1: Match all patterns using grep -qiE ---
typeset -A SCORES=()
typeset -A SUPPRESSIONS=()
typeset -A HARD_TRIGGERS=()
typeset -A GATES=()
typeset -A MATCHED_PATTERNS=()
typeset -a MATCHED_DETAILS=()

while IFS=$'\t' read -r pname regex contributions; do
  # Skip comments and blank lines
  [[ -z "$pname" || "$pname" == \#* ]] && continue

  # Match against user message (case-insensitive extended regex)
  if echo "$PROMPT" | grep -qiE "$regex" 2>/dev/null; then
    MATCHED_PATTERNS[$pname]=1

    # Parse contributions: PROTO:WEIGHT[,PROTO:WEIGHT]
    remaining="$contributions"
    while [[ -n "$remaining" ]]; do
      if [[ "$remaining" == *","* ]]; then
        contrib="${remaining%%,*}"
        remaining="${remaining#*,}"
      else
        contrib="$remaining"
        remaining=""
      fi

      proto="${contrib%%:*}"
      weight_part="${contrib#*:}"

      if [[ "$weight_part" == "GATE" ]]; then
        GATES[$proto]=1
      elif [[ "$weight_part" == *":HARD" ]]; then
        weight="${weight_part%%:*}"
        HARD_TRIGGERS[$proto]=1
        SCORES[$proto]=$(( ${SCORES[$proto]:-0} + weight ))
        MATCHED_DETAILS+=("${pname} -> ${proto}:+${weight}:HARD")
      else
        weight="$weight_part"
        if (( weight < 0 )); then
          abs_weight=$(( -weight ))
          SUPPRESSIONS[$proto]=$(( ${SUPPRESSIONS[$proto]:-0} + abs_weight ))
          MATCHED_DETAILS+=("${pname} -> ${proto}:${weight}")
        else
          SCORES[$proto]=$(( ${SCORES[$proto]:-0} + weight ))
          MATCHED_DETAILS+=("${pname} -> ${proto}:+${weight}")
        fi
      fi
    done
  fi
done < "$PATTERNS_FILE"

# --- Phase 2: Compute final scores and activation ---
typeset -A FINAL_SCORES=()
typeset -a ACTIVATED=()

for proto in "${PRIORITY_ORDER[@]}"; do
  raw=${SCORES[$proto]:-0}
  sup=${SUPPRESSIONS[$proto]:-0}
  final=$(( raw - sup ))
  (( final < 0 )) && final=0
  FINAL_SCORES[$proto]=$final

  # Skip if gated (hard suppress)
  [[ "${GATES[$proto]:-0}" == "1" ]] && continue

  # Activate on hard trigger or threshold
  threshold=${THRESHOLDS[$proto]:-999}
  if [[ "${HARD_TRIGGERS[$proto]:-0}" == "1" ]] || (( final >= threshold )); then
    ACTIVATED+=("$proto")
  fi
done

# --- Phase 3: Build injection XML ---
injection=""
turn_state="clear"

if (( ${#ACTIVATED[@]} > 0 )); then
  turn_state="needs_clarification"
  active_lines=""
  counter=1
  has_tier3=0
  has_clar=0

  for proto in "${ACTIVATED[@]}"; do
    case "$proto" in
      EMOTIONAL)
        signals=""
        [[ -n "${MATCHED_PATTERNS[profanity]:-}" ]] && signals+="profanity, "
        [[ -n "${MATCHED_PATTERNS[frustration_self]:-}" ]] && signals+="frustration, "
        [[ -n "${MATCHED_PATTERNS[stress_self]:-}" ]] && signals+="stress, "
        [[ -n "${MATCHED_PATTERNS[catastrophize]:-}" ]] && signals+="catastrophizing, "
        [[ -n "${MATCHED_PATTERNS[persistent_feeling]:-}" ]] && signals+="persistent feelings, "
        [[ -n "${MATCHED_PATTERNS[helplessness]:-}" ]] && signals+="helplessness, "
        signals="${signals%, }"
        active_lines+="${counter}. Emotional Context -- processing signals detected: ${signals}\n"
        # Emotional support doesn't need clarification enforcement
        turn_state="clear"
        ;;
      CLAR)
        has_clar=1
        triggers=""
        [[ -n "${MATCHED_PATTERNS[vague_terms]:-}" ]] && triggers+="vague terms, "
        [[ -n "${MATCHED_PATTERNS[conflicting_goals]:-}" ]] && triggers+="conflicting goals, "
        [[ -n "${MATCHED_PATTERNS[scope_ambiguous]:-}" ]] && triggers+="ambiguous scope, "
        [[ -n "${MATCHED_PATTERNS[multiple_interp]:-}" ]] && triggers+="multiple interpretations, "
        triggers="${triggers%, }"
        active_lines+="${counter}. Clarification-First -- ${triggers}\n"
        turn_state="needs_clarification"
        ;;
      TIER3)
        has_tier3=1
        triggers=""
        [[ -n "${MATCHED_PATTERNS[commitment_lang]:-}" ]] && triggers+="commitment language, "
        [[ -n "${MATCHED_PATTERNS[deadline_pressure]:-}" ]] && triggers+="deadline pressure, "
        [[ -n "${MATCHED_PATTERNS[high_stakes]:-}" ]] && triggers+="high-stakes domain, "
        [[ -n "${MATCHED_PATTERNS[bias_convergence]:-}" ]] && triggers+="bias convergence, "
        [[ -n "${MATCHED_PATTERNS[values_conflict]:-}" ]] && triggers+="values conflict, "
        [[ -n "${MATCHED_PATTERNS[point_of_no_return]:-}" ]] && triggers+="irreversibility signal, "
        triggers="${triggers%, }"
        active_lines+="${counter}. IHP Tier 3 -- irreversible decision: ${triggers}\n"
        turn_state="needs_clarification"
        ;;
    esac
    (( counter++ ))
  done

  # CONSIDER section
  consider_lines=""
  if (( has_tier3 && has_clar )); then
    consider_lines="- IHP Tier 3 + Clarification merge -- per protocol rules, merge into single conversation\n"
  fi

  # SUPPRESS section
  suppress_lines=""
  for proto in "${PRIORITY_ORDER[@]}"; do
    if [[ "${GATES[$proto]:-0}" == "1" ]]; then
      case "$proto" in
        CLAR) suppress_lines+="- Clarification-First -- user explicitly opted out\n" ;;
        TIER3) suppress_lines+="- IHP Tier 3 -- user said already decided\n" ;;
        EMOTIONAL) suppress_lines+="- Emotional Context -- suppressed\n" ;;
      esac
    fi
  done
  [[ -z "$suppress_lines" ]] && suppress_lines="- none\n"

  injection="<protocol-activation>\nACTIVE (must follow):\n${active_lines}"
  [[ -n "$consider_lines" ]] && injection+="\nCONSIDER:\n${consider_lines}"
  injection+="\nSUPPRESS:\n${suppress_lines}</protocol-activation>"
fi

# If only EMOTIONAL activated, don't block tools
if (( ${#ACTIVATED[@]} == 1 )) && [[ "${ACTIVATED[1]}" == "EMOTIONAL" ]]; then
  turn_state="clear"
fi

# --- Phase 4: Write state file ---
STATE_FILE="$STATE_DIR/${SESSION_ID}.json"

# Read existing clarification round count
prev_round=0
[[ -f "$STATE_FILE" ]] && prev_round=$(jq -r '.clarification_round // 0' "$STATE_FILE" 2>/dev/null || echo 0)

# Increment round if already in NEEDS_CLARIFICATION
clar_round=0
if [[ "$turn_state" == "needs_clarification" ]]; then
  prev_state=""
  [[ -f "$STATE_FILE" ]] && prev_state=$(jq -r '.turn_state // ""' "$STATE_FILE" 2>/dev/null || echo "")
  if [[ "$prev_state" == "needs_clarification" ]]; then
    clar_round=$(( prev_round + 1 ))
  fi
  # Cap at 2 rounds per CLAUDE.md
  if (( clar_round >= 2 )); then
    turn_state="clear"
    clar_round=0
  fi
fi

# Collect matched vague terms
vague_list="[]"
if [[ -n "${MATCHED_PATTERNS[vague_terms]:-}" ]]; then
  vterms=()
  for vt in fast clean better simple good scalable healthy productive efficient proper elegant nice robust modern; do
    if echo "$PROMPT" | grep -qiw "$vt" 2>/dev/null; then
      vterms+=("\"$vt\"")
    fi
  done
  (( ${#vterms[@]} > 0 )) && vague_list="[${(j:, :)vterms}]"
fi

has_conflict="false"
[[ -n "${MATCHED_PATTERNS[conflicting_goals]:-}" ]] && has_conflict="true"

# Build gated list
gated_json="[]"
if (( ${#GATES} > 0 )); then
  gated_items=()
  for g in ${(k)GATES}; do gated_items+=("\"$g\""); done
  gated_json="[${(j:, :)gated_items}]"
fi

cat > "$STATE_FILE" <<STATEEOF
{
  "turn_state": "${turn_state}",
  "scores": {
    "EMOTIONAL": ${FINAL_SCORES[EMOTIONAL]:-0},
    "TIER3": ${FINAL_SCORES[TIER3]:-0},
    "CLAR": ${FINAL_SCORES[CLAR]:-0}
  },
  "vague_terms": ${vague_list},
  "has_conflict": ${has_conflict},
  "gated": ${gated_json},
  "clarification_round": ${clar_round},
  "timestamp": $(date +%s)
}
STATEEOF

# --- Phase 5: Debug output (stderr, doesn't affect JSON) ---
if [[ "${PROTOCOL_DEBUG:-0}" == "1" ]]; then
  {
    echo "=== PROTOCOL ROUTER DEBUG ==="
    echo "Message: \"${PROMPT:0:100}\""
    echo "Matched patterns:"
    for detail in "${MATCHED_DETAILS[@]}"; do echo "  $detail"; done
    echo "Scores:"
    for proto in "${PRIORITY_ORDER[@]}"; do
      raw=${SCORES[$proto]:-0}; sup=${SUPPRESSIONS[$proto]:-0}; fin=${FINAL_SCORES[$proto]:-0}
      thresh=${THRESHOLDS[$proto]:-999}
      flags=""
      [[ "${GATES[$proto]:-0}" == "1" ]] && flags+=" [GATED]"
      [[ "${HARD_TRIGGERS[$proto]:-0}" == "1" ]] && flags+=" [HARD]"
      result_str="NOT ACTIVATED"
      for a in "${ACTIVATED[@]}"; do [[ "$a" == "$proto" ]] && result_str="ACTIVATED"; done
      echo "  ${proto}: raw=${raw} sup=${sup} final=${fin} (threshold=${thresh})${flags} -> ${result_str}"
    done
    echo "Turn state: ${turn_state}"
    echo "=== END DEBUG ==="
  } >&2
fi

# --- Phase 6: Output JSON for hook system ---
if [[ -n "$injection" ]]; then
  injection_text="$(echo -e "$injection")"
  jq -n --arg ctx "$injection_text" '{
    "hookSpecificOutput": {
      "hookEventName": "UserPromptSubmit",
      "additionalContext": $ctx
    }
  }'
fi

exit 0
