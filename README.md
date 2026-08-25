# Omnis

A personal-intelligence workspace architecture for Claude Code (and Antigravity) — a persistent "second brain" agent that manages its own memory as a wiki, runs a meeting-ingestion pipeline, and knows how to delegate token-heavy work to a cheaper coding agent.

**This is the bare skeleton.** No personal data, no memory content, no credentials — just the working architecture. Fork it and make it yours.

## What's here

- **`CLAUDE.md` / `AGENTS.md`** — the identity + operating rules the assistant reads at session start (Claude Code and Antigravity variants of the same config).
- **`knowledge/_Memory/`** — the memory wiki. Ships empty except for `_agent-prompt.md` (the memory agent's own system prompt) and placeholder domain folders. See `.claude/skills/memory/SKILL.md` for how STORE/RECALL/MAINTAIN/INGEST work.
- **`.claude/skills/`** — `memory` (wiki operations), `meeting-ingestor` (audio → transcript → memory pipeline), `delegate` (hand bulk implementation work to a secondary coding agent), `humanizer` (strip AI-writing tells from text, third-party skill included as-is).
- **`agents/meeting-analyst.md`** — the subagent prompt the meeting-ingestor pipeline dispatches to.
- **`scripts/transcribe_meeting.py`** — local Whisper transcription for the meeting pipeline.
- **`.claude/hooks/`** — session-start (loads identity/preferences/overview into context, bounded by a byte cap) and session-end (headless wrap-up + commit).
- **`logs/`**, **`projects/`**, **`.tmp/`** — append-only activity log, scoped project workspaces, gitignored scratch space.

## Getting started

1. Fork/clone this repo.
2. Open it in Claude Code (or Antigravity). On first run, the assistant should interview you and scaffold `knowledge/_Memory/identity/` and `knowledge/_Memory/preferences/` from your answers — see the **Onboarding** section at the bottom of `CLAUDE.md`.
3. Delete whichever placeholder domains under `knowledge/_Memory/` don't apply to you (e.g. drop `academics/` if you're not a student, drop `ventures/` if you don't run a business).
4. If you want MCP integrations (email, finance, browser, etc.), copy `.mcp.json.example` to `.mcp.json` and fill in your own credentials — `.mcp.json` is gitignored, so your secrets never get committed.
5. Wire up `.claude/hooks/session-start.sh` and `session-end.sh` (already referenced in `.claude/settings.json`) — they're bash, so on Windows run Claude Code through Git Bash/WSL or adapt them to PowerShell.

## Design notes worth knowing before you customize

- **Lean hot wiki, not an archive.** The memory wiki is meant to hold only what's currently useful. Git history is the archive — resolved threads and stale dumps get deleted, not accumulated.
- **Prose-first memory.** Entities are narrative paragraphs with inline wikilinks, not bullet-point databases. No `email:`/`phone:`-style key-values in frontmatter — see `_agent-prompt.md` for the exact format.
- **Domain isolation.** `work/` and `personal/` never cross-link. Keeps the wiki honest about which context is which.
- **Explicit approval gate on meeting ingestion.** The meeting pipeline always stops for human review before writing to memory — no fast path, even for a two-minute recording.
- **Delegation is opt-in only.** The `delegate` skill never fires on the assistant's own judgment — only on an explicit "delegate this."
