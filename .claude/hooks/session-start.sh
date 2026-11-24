#!/usr/bin/env bash
# Session-start hook: syncs from remote and loads memory context.
# Capped at MAX_BYTES total to bound per-session token cost.
#
# Emission order is priority order: whatever is emitted first is guaranteed to
# survive the cap. The session buffer goes first because it is the most volatile
# and most decision-relevant file -- it says what is actually in flight. Governing
# protocols come next, then identity, then the static memory map last, since
# _overview.md is the most redundant with the domain overviews it indexes.
#
# Protocols live at knowledge/protocols/, deliberately OUTSIDE knowledge/_Memory/. They
# are governing text, not memory: keeping them out of the wiki stops the memory agent
# treating them as narrative entities and appending to them forever.

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
MEMORY="$WORKSPACE/knowledge/_Memory"
PROTOCOLS="$WORKSPACE/knowledge/protocols"
MAX_BYTES=45000
TOTAL=0

git -C "$WORKSPACE" pull --ff-only 2>/dev/null || true

if [ ! -d "$MEMORY" ]; then
  echo "Memory wiki not found at $MEMORY. Run the onboarding skill to scaffold it."
  exit 0
fi

emit() {
  local f=$1
  [ -f "$f" ] || return 0
  local remaining=$((MAX_BYTES - TOTAL))
  [ "$remaining" -le 0 ] && return 0
  local size
  size=$(wc -c < "$f")
  if [ "$size" -gt "$remaining" ]; then
    head -c "$remaining" "$f"
    echo ""
    echo "[truncated — memory dump cap reached]"
    TOTAL=$MAX_BYTES
  else
    cat "$f"
    echo ""
    TOTAL=$((TOTAL + size))
  fi
}

# Uncommitted knowledge/ and logs/ files untouched for 6+ hours are work a session left behind
# without a wrap-up. Newer ones may belong to a parallel session that is still running, so
# they are not flagged. The memory skill offers WRAP-UP when this block appears.
STALE=$(cd "$WORKSPACE" && { git diff --name-only -z HEAD -- knowledge logs; git ls-files -z --others --exclude-standard -- knowledge logs; } 2>/dev/null | xargs -0 -r sh -c 'find "$@" -maxdepth 0 -mmin +360 2>/dev/null' sh | sort -u)
if [ -n "$STALE" ]; then
  N=$(printf '%s\n' "$STALE" | wc -l)
  echo "## ⚠ Unwrapped work"
  echo "$N uncommitted file(s) under knowledge/ or logs/ untouched for 6+ hours, likely left by a session that never wrapped up. Offer WRAP-UP."
  printf '%s\n' "$STALE" | head -10 | sed 's/^/- /'
  [ "$N" -gt 10 ] && echo "- ...and $((N - 10)) more"
  echo ""
fi

# First run: the wiki still holds only the shipped placeholder overview.
if grep -q "Nothing here yet" "$MEMORY/_overview.md" 2>/dev/null; then
  echo "## ⚠ First run"
  echo "The memory wiki is still the empty skeleton. Run the onboarding skill before any other work."
  echo ""
fi

echo "## Active Session Briefing"
echo ""
emit "$WORKSPACE/logs/_session.md"

echo "## Operating Protocols"
echo ""
for f in "$PROTOCOLS/communication.md" "$PROTOCOLS/scheduling.md" "$PROTOCOLS/_index.md"; do emit "$f"; done

echo "## Identity"
echo ""
for f in "$MEMORY/identity/"*.md; do emit "$f"; done

echo "## Memory Overview"
echo ""
emit "$MEMORY/_overview.md"
