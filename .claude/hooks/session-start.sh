#!/usr/bin/env bash
# Session-start hook: syncs from remote and loads memory context.
# Capped at MAX_BYTES total to bound per-session token cost.

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
MEMORY="$WORKSPACE/knowledge/_Memory"
PROTOCOLS="$WORKSPACE/knowledge/protocols"
MAX_BYTES=30000
TOTAL=0

git -C "$WORKSPACE" pull --ff-only 2>/dev/null || true

if [ ! -d "$MEMORY" ]; then
  echo "Memory wiki not found at $MEMORY. Run bootstrap to scaffold it."
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

echo "## Protocols (always-on)"
echo ""
emit "$PROTOCOLS/communication.md"
emit "$PROTOCOLS/scheduling.md"

echo "## Identity"
echo ""
for f in "$MEMORY/identity/"*.md; do emit "$f"; done

echo "## Preferences"
echo ""
for f in "$MEMORY/preferences/"*.md; do emit "$f"; done

echo "## Memory Overview"
echo ""
emit "$MEMORY/_overview.md"

echo "## Active Session Briefing"
echo ""
emit "$MEMORY/active/_session.md"
