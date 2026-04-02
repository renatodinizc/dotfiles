#!/usr/bin/env zsh
# Test suite for the Protocol Router hook system.
# Run: zsh claude/scripts/test-protocol-hooks.sh
#
# Uses no external test framework. Produces TAP-like output.
# Exit 0 = all pass, exit 1 = failures.

set -uo pipefail

SCRIPT_DIR="${0:A:h}"
STATE_DIR="$HOME/.claude/hook-state"
mkdir -p "$STATE_DIR"

# --- Counters ---
PASS_COUNT=0
FAIL_COUNT=0
TEST_NUM=0

# --- Colors (if terminal supports them) ---
if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; RED=$'\033[31m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  GREEN=""; RED=""; DIM=""; RESET=""
fi

# --- Helpers ---

pass() {
  (( TEST_NUM++ ))
  (( PASS_COUNT++ ))
  echo "${GREEN}ok ${TEST_NUM}${RESET} - $1"
}

fail() {
  (( TEST_NUM++ ))
  (( FAIL_COUNT++ ))
  echo "${RED}not ok ${TEST_NUM}${RESET} - $1"
  [[ -n "${2:-}" ]] && echo "  ${DIM}got: $2${RESET}"
  [[ -n "${3:-}" ]] && echo "  ${DIM}expected: $3${RESET}"
}

# Build JSON input for the router
router_input() {
  local msg="$1"
  local sid="${2:-test-$$}"
  jq -n --arg m "$msg" --arg s "$sid" '{"prompt":$m,"session_id":$s,"hook_event_name":"UserPromptSubmit"}'
}

# Run router, return debug output (stderr) and JSON output (stdout)
run_router() {
  local msg="$1"
  local sid="${2:-test-$$}"
  router_input "$msg" "$sid" | PROTOCOL_DEBUG=1 zsh "$SCRIPT_DIR/protocol-router.sh" 2>/tmp/proto-test-debug
}

# Extract activated protocols from debug output
get_activated() {
  grep " -> ACTIVATED" /tmp/proto-test-debug | awk '{print $1}' | sed 's/://' | sort | tr '\n' ',' | sed 's/,$//'
}

# Extract final score for a protocol from debug output
get_score() {
  local proto="$1"
  grep "^  ${proto}:" /tmp/proto-test-debug | sed -E 's/.*final=([0-9-]+).*/\1/'
}

# Check if a pattern was matched
was_matched() {
  local pattern="$1"
  grep -q "  ${pattern} -> " /tmp/proto-test-debug
}

# Run enforcer with a given session and tool
run_enforcer() {
  local sid="$1"
  local tool="$2"
  printf '{"session_id":"%s","tool_name":"%s","tool_input":{}}' "$sid" "$tool" | \
    zsh "$SCRIPT_DIR/clarification-enforcer.sh"
}

# Write a state file directly
write_state() {
  local sid="$1"
  local state="$2"
  echo "$state" > "$STATE_DIR/${sid}.json"
}

# Run response monitor
run_monitor() {
  local sid="$1"
  local active="${2:-false}"
  local msg="${3:-}"
  jq -n --arg s "$sid" --argjson a "$active" --arg m "$msg" \
    '{"session_id":$s,"stop_hook_active":$a,"last_assistant_message":$m}' | \
    zsh "$SCRIPT_DIR/response-monitor.sh"
}

# Assert activated protocols match expected (comma-separated, sorted)
assert_activated() {
  local label="$1"
  local expected="$2"
  local actual
  actual="$(get_activated)"
  [[ -z "$actual" ]] && actual="NONE"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label" "$actual" "$expected"
  fi
}

# Assert JSON output contains expected field/value
assert_json_field() {
  local label="$1"
  local json="$2"
  local jq_expr="$3"
  local expected="$4"
  local actual
  actual="$(printf '%s' "$json" | jq -r "$jq_expr" 2>/dev/null)"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label" "$actual" "$expected"
  fi
}

# Assert output is empty (no JSON emitted)
assert_empty() {
  local label="$1"
  local output="$2"
  local trimmed="${output//[$'\n\r\t ']}"
  if [[ -z "$trimmed" || "$trimmed" == "null" ]]; then
    pass "$label"
  else
    fail "$label" "${output:0:80}" "(empty)"
  fi
}

# Assert output is non-empty
assert_nonempty() {
  local label="$1"
  local output="$2"
  local trimmed="${output//[$'\n\r\t ']}"
  if [[ -n "$trimmed" && "$trimmed" != "null" ]]; then
    pass "$label"
  else
    fail "$label" "(empty)" "(non-empty JSON)"
  fi
}

# Assert JSON output has decision=block
assert_blocks() {
  local label="$1"
  local output="$2"
  local decision
  decision="$(printf '%s' "$output" | jq -r '.decision // empty' 2>/dev/null)"
  if [[ "$decision" == "block" ]]; then
    pass "$label"
  else
    fail "$label" "${decision:-empty}" "block"
  fi
}

# Clean up state files for a session
cleanup() {
  rm -f "$STATE_DIR/${1}.json" 2>/dev/null
}

# ============================================================================
echo "# Protocol Router — Scoring & Activation"
echo ""
# ============================================================================

# --- TIER3 tests ---

run_router "I've decided to quit my job by Friday" "t-tier3-1" > /dev/null
assert_activated "TIER3: commitment + deadline + high_stakes converge" "TIER3"
cleanup "t-tier3-1"

run_router "I've decided to quit my job. I need to tell them by Friday." "t-tier3-2" > /dev/null
assert_activated "TIER3: commitment + deadline + high_stakes (multi-sentence)" "TIER3"
cleanup "t-tier3-2"

run_router "I accepted the job offer. No turning back now." "t-tier3-3" > /dev/null
assert_activated "TIER3: commitment + point_of_no_return + high_stakes" "TIER3"
cleanup "t-tier3-3"

# --- TIER3 suppression by code context ---

run_router "I've decided to use HashMap for the cache" "t-tier3-sup1" > /dev/null
assert_activated "TIER3 suppressed: code context (HashMap)" "NONE"
cleanup "t-tier3-sup1"

run_router "I've decided to let the function return early" "t-tier3-sup2" > /dev/null
assert_activated "TIER3 suppressed: code context (let, function)" "NONE"
cleanup "t-tier3-sup2"

run_router "I'm going to quit the loop using break" "t-tier3-sup3" > /dev/null
assert_activated "TIER3 suppressed: commitment_lang but tech context" "NONE"
cleanup "t-tier3-sup3"

# --- TIER3 below threshold ---

run_router "I've been thinking about whether to move" "t-tier3-low" > /dev/null
assert_activated "TIER3 below threshold: no convergence" "NONE"
cleanup "t-tier3-low"

# --- EMOTIONAL tests ---

run_router "This code is shit, nothing works" "t-emo-1" > /dev/null
assert_activated "EMOTIONAL: profanity (hard trigger) + catastrophize" "EMOTIONAL"
cleanup "t-emo-1"

run_router "fuck this, I give up, nothing ever works" "t-emo-2" > /dev/null
assert_activated "EMOTIONAL: profanity + helplessness + catastrophize" "EMOTIONAL"
cleanup "t-emo-2"

run_router "I'm so stressed, I can't sleep, everything is falling apart" "t-emo-3" > /dev/null
assert_activated "EMOTIONAL: stress + catastrophize converge" "EMOTIONAL"
cleanup "t-emo-3"

run_router "Something feels off, I should be happy but I'm not" "t-emo-4" > /dev/null
assert_activated "EMOTIONAL: persistent_feeling signal" "NONE"
# persistent_feeling alone = 3, below threshold 4. Correct behavior.
cleanup "t-emo-4"

# --- EMOTIONAL suppression by tech context ---

run_router "I'm stressed about the memory leak" "t-emo-sup1" > /dev/null
assert_activated "EMOTIONAL suppressed: tech context (memory leak)" "NONE"
cleanup "t-emo-sup1"

run_router "Damn, the git merge failed again" "t-emo-sup2" > /dev/null
assert_activated "EMOTIONAL: profanity hard-triggers even with tech context" "EMOTIONAL"
# "damn" is a HARD trigger — bypasses threshold regardless of suppression.
# This is by design: hard triggers represent signals too strong to suppress.
cleanup "t-emo-sup2"

# --- EMOTIONAL does not block tools ---

out=$(run_router "This is shit, everything is broken" "t-emo-state")
state=$(jq -r '.turn_state' "$STATE_DIR/t-emo-state.json")
if [[ "$state" == "clear" ]]; then
  pass "EMOTIONAL: turn_state is 'clear' (doesn't block tools)"
else
  fail "EMOTIONAL: turn_state should be 'clear'" "$state" "clear"
fi
cleanup "t-emo-state"

# --- CLARIFICATION tests ---

run_router "I want fast response times but also need comprehensive validation" "t-clar-1" > /dev/null
assert_activated "CLAR: vague_terms + conflicting_goals converge" "CLAR"
cleanup "t-clar-1"

run_router "Should I make it better and more scalable, or keep it simple? What do you think?" "t-clar-2" > /dev/null
assert_activated "CLAR: vague_terms + conflicting_goals + multiple_interp" "CLAR"
cleanup "t-clar-2"

run_router "I want a simple, clean, elegant solution" "t-clar-3" > /dev/null
# Three vague terms = 2 (vague_terms matches once regardless of count)
# Plus no other signal, total = 2, below threshold 5
assert_activated "CLAR below threshold: vague terms alone insufficient" "NONE"
cleanup "t-clar-3"

run_router "Make the API better and more scalable" "t-clar-4" > /dev/null
assert_activated "CLAR below threshold: only vague_terms (2 < 5)" "NONE"
cleanup "t-clar-4"

# --- CLARIFICATION: GATE mechanism ---

run_router "Just do it, clean up the auth module" "t-clar-gate1" > /dev/null
assert_activated "CLAR GATED: 'just do it' suppresses clarification" "NONE"
cleanup "t-clar-gate1"

run_router "I know what I want, make it better and scalable" "t-clar-gate2" > /dev/null
assert_activated "CLAR GATED: 'I know what I want' suppresses" "NONE"
cleanup "t-clar-gate2"

run_router "Go ahead and fix everything" "t-clar-gate3" > /dev/null
assert_activated "CLAR GATED: 'go ahead and' suppresses" "NONE"
cleanup "t-clar-gate3"

# --- CLARIFICATION: clear-scoped suppression ---

run_router "Rename foo to process_batch" "t-clar-clear1" > /dev/null
assert_activated "CLAR suppressed: clear scoped task (rename)" "NONE"
cleanup "t-clar-clear1"

run_router "Fix the typo in the README" "t-clar-clear2" > /dev/null
assert_activated "CLAR suppressed: clear scoped task (fix the typo)" "NONE"
cleanup "t-clar-clear2"

run_router "Run the tests" "t-clar-clear3" > /dev/null
assert_activated "CLAR suppressed: clear scoped task (run tests)" "NONE"
cleanup "t-clar-clear3"

# --- Multi-protocol activation ---

run_router "Fuck, I'm so stressed. I've decided to quit my job by Friday. Everything is falling apart." "t-multi-1" > /dev/null
assert_activated "Multi: EMOTIONAL + TIER3 (profanity + stress + commitment + deadline + stakes)" "EMOTIONAL,TIER3"
cleanup "t-multi-1"

# --- No activation (baseline) ---

run_router "hello" "t-none-1" > /dev/null
assert_activated "No activation: simple greeting" "NONE"
cleanup "t-none-1"

run_router "fix the bug in auth.rs" "t-none-2" > /dev/null
assert_activated "No activation: clear task with file extension" "NONE"
cleanup "t-none-2"

run_router "What does this function do?" "t-none-3" > /dev/null
assert_activated "No activation: simple question about code" "NONE"
cleanup "t-none-3"

# ============================================================================
echo ""
echo "# Protocol Router — State File Output"
echo ""
# ============================================================================

out=$(run_router "I want fast response but need validation too" "t-state-clar")
state_json=$(cat "$STATE_DIR/t-state-clar.json")
assert_json_field "State: turn_state is needs_clarification" "$state_json" '.turn_state' "needs_clarification"
assert_json_field "State: has_conflict is true" "$state_json" '.has_conflict' "true"
assert_json_field "State: clarification_round is 0" "$state_json" '.clarification_round' "0"
cleanup "t-state-clar"

out=$(run_router "Rename foo to bar" "t-state-clear")
state_json=$(cat "$STATE_DIR/t-state-clear.json")
assert_json_field "State: turn_state is clear for scoped task" "$state_json" '.turn_state' "clear"
cleanup "t-state-clear"

# --- Clarification round counter ---

# Each prompt must trigger CLAR (score >= 5) to stay in needs_clarification
run_router "What's the best way to improve this and make it scalable?" "t-round" > /dev/null
round0=$(jq -r '.clarification_round' "$STATE_DIR/t-round.json")
run_router "I want it to be cleaner but also need good performance, what do you think?" "t-round" > /dev/null
round1=$(jq -r '.clarification_round' "$STATE_DIR/t-round.json")
run_router "Should I make it fast but also keep it simple and robust?" "t-round" > /dev/null
round2_state=$(jq -r '.turn_state' "$STATE_DIR/t-round.json")

if [[ "$round0" == "0" ]]; then pass "Round counter: starts at 0"; else fail "Round counter: starts at 0" "$round0" "0"; fi
if [[ "$round1" == "1" ]]; then pass "Round counter: increments to 1"; else fail "Round counter: increments to 1" "$round1" "1"; fi
if [[ "$round2_state" == "clear" ]]; then pass "Round counter: caps at 2, forces clear"; else fail "Round counter: caps at 2, forces clear" "$round2_state" "clear"; fi
cleanup "t-round"

# ============================================================================
echo ""
echo "# Protocol Router — Injection Format"
echo ""
# ============================================================================

out=$(run_router "I've decided to quit my job by Friday" "t-inj-1")
assert_nonempty "Injection: non-empty when TIER3 activates" "$out"
ctx=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext // ""')
if [[ -n "$ctx" && "$ctx" != "null" ]]; then
  pass "Injection: has additionalContext"
else
  fail "Injection: has additionalContext" "(empty)" "(non-empty)"
fi
if [[ "$ctx" == *"<protocol-activation>"* ]]; then
  pass "Injection: contains <protocol-activation> XML"
else
  fail "Injection: contains <protocol-activation> XML" "${ctx:0:80}" "<protocol-activation>..."
fi
if [[ "$ctx" == *"ACTIVE (must follow):"* ]]; then
  pass "Injection: contains ACTIVE section"
else
  fail "Injection: contains ACTIVE section" "${ctx:0:80}" "ACTIVE (must follow):..."
fi
if [[ "$ctx" == *"IHP Tier 3"* ]]; then
  pass "Injection: mentions IHP Tier 3 by name"
else
  fail "Injection: mentions IHP Tier 3 by name" "${ctx:0:80}" "...IHP Tier 3..."
fi
cleanup "t-inj-1"

out=$(run_router "hello world" "t-inj-2")
assert_empty "Injection: empty when no protocols activate" "$out"
cleanup "t-inj-2"

# GATE suppression shows in SUPPRESS section
out=$(run_router "Just do it, make it better and more scalable, what do you think?" "t-inj-gate")
ctx=$(echo "$out" | jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null)
if [[ -n "$ctx" && "$ctx" == *"SUPPRESS:"* && "$ctx" == *"opted out"* ]]; then
  pass "Injection: SUPPRESS section shows GATE reason"
else
  # If nothing activated at all (GATE prevented CLAR, nothing else triggered), that's also valid
  if [[ -z "$out" ]]; then
    pass "Injection: GATE suppressed all protocols, no injection (valid)"
  else
    fail "Injection: SUPPRESS section shows GATE reason" "${ctx:0:80}" "...opted out..."
  fi
fi
cleanup "t-inj-gate"

# ============================================================================
echo ""
echo "# Clarification Enforcer — Tool Blocking"
echo ""
# ============================================================================

# Set up needs_clarification state
write_state "t-enf" '{"turn_state":"needs_clarification","vague_terms":["clean","scalable"],"has_conflict":true,"clarification_round":0}'

out=$(run_enforcer "t-enf" "Bash")
assert_json_field "Enforcer: denies Bash when needs_clarification" "$out" '.hookSpecificOutput.permissionDecision' "deny"

out=$(run_enforcer "t-enf" "Write")
assert_json_field "Enforcer: denies Write when needs_clarification" "$out" '.hookSpecificOutput.permissionDecision' "deny"

out=$(run_enforcer "t-enf" "Edit")
assert_json_field "Enforcer: denies Edit when needs_clarification" "$out" '.hookSpecificOutput.permissionDecision' "deny"

out=$(run_enforcer "t-enf" "Agent")
assert_json_field "Enforcer: denies Agent when needs_clarification" "$out" '.hookSpecificOutput.permissionDecision' "deny"

# Deny message includes vague terms
out=$(run_enforcer "t-enf" "Bash")
reason=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""')
if [[ "$reason" == *"clean"* && "$reason" == *"scalable"* ]]; then
  pass "Enforcer: deny reason includes vague terms"
else
  fail "Enforcer: deny reason includes vague terms" "${reason:0:80}" "...clean...scalable..."
fi

if [[ "$reason" == *"Conflicting goals"* ]]; then
  pass "Enforcer: deny reason mentions conflicting goals"
else
  fail "Enforcer: deny reason mentions conflicting goals" "${reason:0:80}" "...Conflicting goals..."
fi

cleanup "t-enf"

# --- Clear state: allow everything ---

write_state "t-enf-clear" '{"turn_state":"clear","vague_terms":[],"has_conflict":false,"clarification_round":0}'

out=$(run_enforcer "t-enf-clear" "Bash")
assert_empty "Enforcer: allows Bash when clear" "$out"

out=$(run_enforcer "t-enf-clear" "Write")
assert_empty "Enforcer: allows Write when clear" "$out"

cleanup "t-enf-clear"

# --- No state file: allow ---

cleanup "t-enf-nostate"
out=$(run_enforcer "t-enf-nostate" "Bash")
assert_empty "Enforcer: allows when no state file exists" "$out"

# ============================================================================
echo ""
echo "# Response Monitor — Anti-Sycophancy"
echo ""
# ============================================================================

out=$(run_monitor "t-mon-1" false "Great question! Let me explain how this works...")
assert_blocks "Monitor: blocks 'Great question!'" "$out"

out=$(run_monitor "t-mon-2" false "Excellent point! I agree completely.")
assert_blocks "Monitor: blocks 'Excellent point!'" "$out"

out=$(run_monitor "t-mon-3" false "That's a wonderful idea! Let me help.")
assert_blocks "Monitor: blocks 'That's a wonderful..'" "$out"

out=$(run_monitor "t-mon-4" false "Absolutely! Here is what I think.")
assert_blocks "Monitor: blocks 'Absolutely!'" "$out"

out=$(run_monitor "t-mon-5" false "Love this approach! Let me build on it.")
assert_blocks "Monitor: blocks 'Love this...'" "$out"

out=$(run_monitor "t-mon-6" false "The issue is in the authentication middleware.")
assert_empty "Monitor: allows substantive opening" "$out"

out=$(run_monitor "t-mon-7" false "Here are three approaches to consider:")
assert_empty "Monitor: allows direct opening" "$out"

out=$(run_monitor "t-mon-8" false "I found the bug. It is on line 42.")
assert_empty "Monitor: allows factual opening" "$out"

# Edge: "Great" not followed by sycophantic pattern
out=$(run_monitor "t-mon-9" false "Greater than expected performance was observed.")
assert_empty "Monitor: allows 'Greater than...' (not sycophancy)" "$out"

# ============================================================================
echo ""
echo "# Response Monitor — Infinite Loop Prevention"
echo ""
# ============================================================================

out=$(run_monitor "t-loop-1" true "Great question! This should be blocked but stop_hook_active is true.")
assert_empty "Monitor: allows through when stop_hook_active=true" "$out"

# ============================================================================
echo ""
echo "# Response Monitor — Clarification Skip Detection"
echo ""
# ============================================================================

write_state "t-mon-skip" '{"turn_state":"needs_clarification","vague_terms":["better"],"has_conflict":false,"clarification_round":0}'

out=$(run_monitor "t-mon-skip" false "I will refactor the code to make it better using a factory pattern.")
assert_blocks "Monitor: blocks response without questions when needs_clarification" "$out"
reason=$(printf '%s' "$out" | jq -r '.reason // ""')
if [[ "$reason" == *"Clarification-First"* ]]; then
  pass "Monitor: clarification skip reason mentions protocol"
else
  fail "Monitor: clarification skip reason mentions protocol" "${reason:0:80}" "...Clarification-First..."
fi
cleanup "t-mon-skip"

# Response WITH questions should pass
write_state "t-mon-ok" '{"turn_state":"needs_clarification","vague_terms":["better"],"has_conflict":false,"clarification_round":0}'

out=$(run_monitor "t-mon-ok" false "What does 'better' mean here? Are you optimizing for speed or readability?")
assert_empty "Monitor: allows response with clarifying questions" "$out"
cleanup "t-mon-ok"

# ============================================================================
echo ""
echo "# Cross-Hook Integration"
echo ""
# ============================================================================

# Full pipeline: vague prompt -> router -> enforcer blocks -> clarification clears
run_router "I want fast response times but need comprehensive validation" "t-e2e" > /dev/null
out=$(run_enforcer "t-e2e" "Bash")
assert_json_field "E2E: enforcer blocks after vague prompt" "$out" '.hookSpecificOutput.permissionDecision' "deny"

# User provides clarification -> router clears state
run_router "I mean p99 latency under 200ms, validation can be async" "t-e2e" > /dev/null
out=$(run_enforcer "t-e2e" "Bash")
assert_empty "E2E: enforcer allows after clear clarification" "$out"
cleanup "t-e2e"

# GATE in router -> enforcer allows
run_router "Just do it, make it better and more scalable, what do you think?" "t-e2e-gate" > /dev/null
out=$(run_enforcer "t-e2e-gate" "Bash")
assert_empty "E2E: enforcer allows when GATE suppressed clarification" "$out"
cleanup "t-e2e-gate"

# EMOTIONAL doesn't block tools
run_router "This is shit, everything is broken" "t-e2e-emo" > /dev/null
out=$(run_enforcer "t-e2e-emo" "Bash")
assert_empty "E2E: enforcer allows after emotional activation (tools not blocked)" "$out"
cleanup "t-e2e-emo"

# ============================================================================
echo ""
echo "# Edge Cases"
echo ""
# ============================================================================

# Empty prompt
run_router "" "t-edge-empty" > /dev/null 2>&1
assert_activated "Edge: empty prompt -> no activation" "NONE"
cleanup "t-edge-empty"

# Very short prompt
run_router "hi" "t-edge-short" > /dev/null
assert_activated "Edge: very short prompt -> no activation" "NONE"
cleanup "t-edge-short"

# Code fence suppression
run_router '```rust
fn main() {
    println!("better");
}
```' "t-edge-fence" > /dev/null
assert_activated "Edge: code fence suppresses vague term 'better'" "NONE"
cleanup "t-edge-fence"

# Already-decided suppression
run_router "I've already thought this through. I'm going to leave my job." "t-edge-already" > /dev/null
# commitment_lang (+2) + high_stakes (+3) + already_decided (-2) = 3. Below 6.
score=$(get_score "TIER3")
if (( score < 6 )); then
  pass "Edge: 'already thought this through' reduces TIER3 score below threshold"
else
  fail "Edge: 'already thought this through' reduces TIER3 score below threshold" "score=$score" "<6"
fi
cleanup "t-edge-already"

# ============================================================================
echo ""
echo "# Performance"
echo ""
# ============================================================================

# Router should complete within 1 second even for complex messages
start_ms=$(python3 -c 'import time; print(int(time.time()*1000))')
run_router "I've decided to quit my job. I need to tell them by Friday. I'm so stressed about it. Everything is falling apart. I want a clean break but also need to maintain good relationships. What do you think is the best way to handle this?" "t-perf" > /dev/null
end_ms=$(python3 -c 'import time; print(int(time.time()*1000))')
elapsed=$(( end_ms - start_ms ))
if (( elapsed < 1000 )); then
  pass "Performance: router completes in ${elapsed}ms (< 1s)"
else
  fail "Performance: router completes in ${elapsed}ms" "${elapsed}ms" "< 1000ms"
fi
cleanup "t-perf"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "---"
total=$(( PASS_COUNT + FAIL_COUNT ))
echo "${PASS_COUNT}/${total} tests passed"

if (( FAIL_COUNT > 0 )); then
  echo "${RED}${FAIL_COUNT} test(s) failed${RESET}"
  exit 1
else
  echo "${GREEN}All tests passed${RESET}"
  exit 0
fi
