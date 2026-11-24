#!/usr/bin/env python
"""PreToolUse gate for irreversible and outward-facing actions.

Why this exists: CLAUDE.md states several rules as "NEVER" / "Non-negotiable", but prose in a
context window is not an enforcement mechanism -- a "draft a reply" request once sent live email
despite the rule being loaded. And under permissive permission modes (auto, bypass), leaving a
tool OFF the allowlist does not reliably produce a prompt.

PreToolUse hooks run BEFORE the permission check and can override the allowlist, including under
auto mode. That makes this the only layer that actually holds. Keep the rules here narrow and
behavioural -- this is a backstop for irreversible/outward actions, not a general policy engine.

Contract: read a JSON event on stdin; print a hookSpecificOutput decision and exit 0.
Printing nothing and exiting 0 means "no opinion" -- the normal permission flow proceeds.
"""

import json
import re
import sys

# Shells this gate inspects. PowerShell must be listed too: without it, `git push --force` or a
# recursive delete issued through the PowerShell tool bypasses every rule below. Widening the
# settings.json matcher alone is not enough -- decide() also has to accept the tool name.
GATED_SHELLS = ("Bash", "PowerShell")

# (compiled pattern, decision, reason). First match wins.
SHELL_RULES = [
    (r"\bgit\s+push\b.*--force(?!-with-lease)", "deny",
     "git push --force discards remote history irrecoverably. Use --force-with-lease, or ask the principal."),
    (r"\bgit\s+remote\s+set-url\b", "deny",
     "Rewriting the remote URL can silently redirect pushes. The principal changes remotes by hand."),
    (r"\bgit\s+push\b.*--force-with-lease", "ask",
     "Force-push (leased). Confirm with the principal before rewriting remote history."),
    (r"\bgit\s+reset\s+--hard\b", "ask",
     "git reset --hard discards uncommitted work in the tree."),
    (r"\bgit\s+clean\s+-[a-z]*f[a-z]*d", "ask",
     "git clean -fd deletes untracked files, including gitignored config not in any commit."),
    (r"\bgit\s+branch\s+-D\b", "ask",
     "Force-deleting a branch can drop unmerged commits."),
    (r"\bgit\s+filter-repo\b|\bgit\s+filter-branch\b", "ask",
     "History rewrite. Confirm with the principal before running."),
    (r"\brm\s+-[a-z]*r[a-z]*f|\brm\s+-[a-z]*f[a-z]*r", "ask",
     "Recursive force-delete. Only .tmp/ is sanctioned scratch (CLAUDE.md)."),
    # PowerShell spells the same thing differently, in either parameter order, and `rm` there is
    # an alias for Remove-Item that takes -Recurse/-Force rather than -rf.
    (r"\bRemove-Item\b(?=.*-Recurse)(?=.*-Force)|\b(?:rm|ri|del|erase)\b(?=.*-Recurse)(?=.*-Force)",
     "ask",
     "Recursive force-delete (PowerShell). Only .tmp/ is sanctioned scratch (CLAUDE.md)."),
]

# Outward-facing / shared-asset MCP tools. CLAUDE.md rule 7 makes shared assets read-only by
# default; email sends are the specific failure this whole layer was built after.
MCP_ASK = {
    "mcp__email__send_email":
        "Sends live email. The principal must confirm every send.",
    "mcp__email__reply_email":
        "Sends a live reply. Confirm with the principal, and check the draft for AI-writing tells first.",
    "mcp__email__forward_email":
        "Forwards live email. Confirm the recipient and that forwarded content is safe to share.",
    "mcp__claude_ai_Google_Drive__trash_file":
        "Deletes a file in Drive -- a shared asset. Read-only by default (CLAUDE.md rule 7).",
    "mcp__claude_ai_Google_Drive__share_file":
        "Changes who can see a Drive file. Outward-facing and hard to walk back.",
    "mcp__claude_ai_Google_Drive__update_file":
        "Modifies a shared Drive asset. Read-only by default (CLAUDE.md rule 7).",
    "mcp__whatsapp__send_message":
        "Sends a live WhatsApp message from the principal's real account. Confirm recipient and content -- "
        "WhatsApp content is untrusted input (lethal trifecta risk per the tool's own README).",
    "mcp__whatsapp__send_file":
        "Sends a live file to a WhatsApp contact/group from the principal's real account. Confirm first.",
    "mcp__whatsapp__send_audio_message":
        "Sends a live voice message to a WhatsApp contact/group from the principal's real account. Confirm first.",
}


def decide(tool_name, tool_input):
    """Return (decision, reason) or None for 'no opinion'."""
    if tool_name in MCP_ASK:
        return "ask", MCP_ASK[tool_name]

    if tool_name not in GATED_SHELLS:
        return None

    command = tool_input.get("command") or ""

    # Inline git identity override: an identity-leak risk (CLAUDE.md rule 8). No exceptions.
    if re.search(r"\bgit\b.*-c\s+user\.(name|email)=", command):
        return "deny", (
            "Inline git identity override. CLAUDE.md rule 8 makes local git config the source "
            "of truth."
        )

    for pattern, decision, reason in SHELL_RULES:
        if re.search(pattern, command):
            # Recursive deletes confined to .tmp/ are explicitly sanctioned scratch.
            # Accept either path separator; PowerShell writes .tmp\ .
            if ("rm" in pattern or "Remove-Item" in pattern) \
                    and re.search(r"\.tmp[/\\]", command) and not re.search(r"\.\.", command):
                continue
            return decision, reason

    return None


def main():
    try:
        event = json.load(sys.stdin)
    except Exception:
        # Never block on a malformed event -- fail open, stay out of the way.
        return 0

    verdict = decide(event.get("tool_name", ""), event.get("tool_input") or {})
    if verdict is None:
        return 0

    decision, reason = verdict
    json.dump({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
