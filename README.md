# Omnis

A personal-intelligence workspace architecture for Claude Code (and Antigravity) — a persistent "second brain" agent that manages its own memory as a wiki, runs a meeting-ingestion pipeline, and knows how to delegate token-heavy work to a cheaper coding agent.

**This is the bare skeleton.** No personal data, no memory content, no credentials — just the working architecture. Fork it and make it yours.

## What's here

- **`CLAUDE.md` / `AGENTS.md`** — the identity + operating rules the assistant reads at session start (Claude Code and Antigravity variants of the same config).
- **`knowledge/_Memory/`** — the memory wiki. Ships empty except for `_agent-prompt.md` (the memory agent's own system prompt) and placeholder domain folders. See `.claude/skills/memory/SKILL.md` for how STORE/RECALL/MAINTAIN/INGEST work.
- **`knowledge/protocols/`** — situational governing text (communication tone, scheduling conventions, tool invocation reference) kept deliberately outside the memory wiki so it doesn't get treated as narrative memory. Loads on demand except for `communication.md`/`scheduling.md`, which auto-load every session.
- **`.claude/skills/`** — `onboarding` (build/grow the memory wiki — an ongoing process, not a one-time step), `memory` (wiki operations), `meeting-ingestor` (audio → transcript → memory pipeline), `delegate` (hand bulk implementation work to a secondary coding agent), `humanizer` (strip AI-writing tells from text, third-party skill included as-is). **`.agents/skills/`** mirrors the four core skills (not `humanizer`, which is Claude Code-plugin shaped) for Antigravity (`agy`), which reads skills from `.agents/` rather than `.claude/`.
- **`agents/meeting-analyst.md`** — the subagent prompt the meeting-ingestor pipeline dispatches to.
- **`scripts/transcribe_meeting.py`** — local Whisper transcription for the meeting pipeline.
- **`.claude/hooks/`** — session-start (loads identity/preferences/overview into context, bounded by a byte cap) and session-end (headless wrap-up + commit). Both `.claude/settings.json` and `.gemini/settings.json` wire `SessionStart` to the same `session-start.sh` script — one hook script, two engines. `.gemini/settings.json` only wires `SessionStart`: an `agy` session gets no `SessionEnd` wrap-up and no pre-tool-use gate, so treat wrap-up and confirming irreversible actions as the driver's job when running under `agy`.
- **`logs/`**, **`projects/`**, **`.tmp/`** — append-only activity log, scoped project workspaces, gitignored scratch space.

## Getting started

1. Fork/clone this repo.
2. Open it in Claude Code (or Antigravity). On first run, the assistant should invoke the `onboarding` skill, interview you, and scaffold `knowledge/_Memory/identity/` and `knowledge/_Memory/preferences/` from your answers — see `.claude/skills/onboarding/SKILL.md` and the **Onboarding** section at the bottom of `CLAUDE.md`.
3. Delete whichever placeholder domains under `knowledge/_Memory/` don't apply to you (e.g. drop `academics/` if you're not a student, drop `ventures/` if you don't run a business).
4. MCP integrations: email is already wired up in `.mcp.json.example` and `.gemini/settings.json` via `npx github:kerodkibatu/email-mcp` — no local path or credentials to fill in, it walks you through connecting your own inbox the first time it runs (works with Outlook once that's set up on this machine). Copy `.mcp.json.example` to `.mcp.json` to activate it for Claude Code (`agy` picks it up automatically from `.gemini/settings.json`). For anything else (finance, browser, etc.), fill in your own credentials in `.mcp.json` — it's gitignored, so secrets never get committed.
5. Wire up `.claude/hooks/session-start.sh` and `session-end.sh` (already referenced in `.claude/settings.json`) — they're bash, so on Windows run Claude Code through Git Bash/WSL or adapt them to PowerShell.
6. **Running with Antigravity (`agy`)**: `.gemini/settings.json` already wires the same `session-start.sh` script into `agy`'s `SessionStart` hook, and `agy` reads its skills from `.agents/skills/` (already mirrored from `.claude/skills/`) rather than `.claude/skills/`. If you're not on Windows with Git at the default install path, fix the hardcoded `C:\Program Files\Git\bin\bash.exe` path in `.gemini/settings.json`'s hook command to wherever `bash` actually lives on your machine. `agy` only gets `SessionStart` here — no session-end wrap-up, no pre-tool-use confirmation gate — so be more deliberate about wrap-up and irreversible actions when driving through `agy`.
7. **Keep going.** Onboarding isn't a one-time step — the wiki is meant to keep growing every session. The `onboarding` skill re-triggers itself whenever it notices a gap (a placeholder domain, a new person/project with nowhere to live), so don't expect a "finished" wiki — expect a wiki that's always slightly behind your actual life and closing the gap in small increments.

## Design notes worth knowing before you customize

- **Lean hot wiki, not an archive.** The memory wiki is meant to hold only what's currently useful. Git history is the archive — resolved threads and stale dumps get deleted, not accumulated.
- **Prose-first memory.** Entities are narrative paragraphs with inline wikilinks, not bullet-point databases. No `email:`/`phone:`-style key-values in frontmatter — see `_agent-prompt.md` for the exact format.
- **Domain isolation.** `work/` and `personal/` never cross-link. Keeps the wiki honest about which context is which.
- **Explicit approval gate on meeting ingestion.** The meeting pipeline always stops for human review before writing to memory — no fast path, even for a two-minute recording.
- **Delegation is opt-in only.** The `delegate` skill never fires on the assistant's own judgment — only on an explicit "delegate this."
