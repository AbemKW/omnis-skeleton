#!/usr/bin/env bash
# SessionEnd hook: automatic session wrap-up.
# Reads _agent-prompt.md verbatim (same quote-gate discipline as interactive dispatch),
# has a headless haiku agent do STORE-mode wrap-up, then commits/pushes.

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
AGENT_PROMPT="$WORKSPACE/knowledge/_Memory/_agent-prompt.md"

if [ ! -f "$AGENT_PROMPT" ]; then
  exit 0
fi

claude --model haiku -p "$(cat <<PROMPT
$(cat "$AGENT_PROMPT")

---
MODE: STORE (session wrap-up)
You are running as the automated SessionEnd hook for the principal's Omnis workspace. Today is $DATE, $TIME.
In one pass:
1. Append a timestamped entry to logs/$DATE.md summarizing what happened this session.
2. Update knowledge/_Memory/active/_session.md if any active thread's status changed.
3. Fold durable facts into the relevant permanent entity files if a thread resolved (then delete the resolved active/<slug>.md and remove its _session.md section).
4. If _session.md now exceeds ~7 active threads or looks stale, note it in a ## System Notices block in _session.md but do NOT run a full MAINTAIN pass here — that stays a separate background dispatch.
Work silently — no user interaction is possible. If nothing changed this session, do nothing and exit cleanly.
PROMPT
)" --dangerously-skip-permissions 2>/dev/null || true

git -C "$WORKSPACE" add -A 2>/dev/null || true
git -C "$WORKSPACE" commit -m "Session wrap-up $DATE $TIME" 2>/dev/null || true
git -C "$WORKSPACE" push 2>/dev/null || true
