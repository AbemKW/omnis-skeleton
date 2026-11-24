# Omnis

A personal-intelligence workspace for Claude Code (and Antigravity): a persistent "second brain" assistant that keeps its own memory as a wiki, learns how you want it to behave, and gets sharper every session.

**This is the bare skeleton.** No personal data, no memory content, no credentials — just the working architecture. Create your own **private** copy and make it yours, name included.

## Getting started

1. **Make your own private copy.** Click **Use this template → Create a new repository**, pick a name, and set it to **Private**. (Don't fork: a fork of a public repo stays public, and your wiki will hold personal facts.)
2. **Install the tools** (Windows, in PowerShell):
   ```powershell
   winget install --id Git.Git -e
   winget install --id GitHub.cli -e
   winget install --id Python.Python.3.12 -e
   irm https://claude.ai/install.ps1 | iex
   ```
   Close and reopen PowerShell afterwards so the new commands are on PATH. (macOS: `brew install git gh python` and `curl -fsSL https://claude.ai/install.sh | bash`.)
3. **Set your git identity and sign in to GitHub** (once per machine):
   ```powershell
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   gh auth login
   ```
4. **Clone and open:**
   ```powershell
   gh repo clone <your-username>/<your-repo>
   cd <your-repo>
   claude
   ```
   Log in with your Claude account when asked.
5. **Onboard.** The first session shows `⚠ First run`. Say "let's set you up" — the `onboarding` skill asks what to name your assistant, renames it everywhere, interviews you, and fills the wiki.
6. **End sessions with "wrap up".** That stores anything durable, logs the session, commits, and pushes to your private repo.

## What's here

- **`CLAUDE.md` / `AGENTS.md`** — identity + operating rules (Claude Code and Antigravity variants of the same config).
- **`agents/memory-agent.md`** — the memory agent's system prompt: wiki layout, file formats, STORE/RECALL/MAINTAIN/INGEST/WRAP-UP mechanics.
- **`knowledge/_Memory/`** — the memory wiki. Ships empty except for placeholder domain overviews.
- **`knowledge/protocols/`** — how the assistant behaves (tone, scheduling, tool reference). Kept outside the wiki on purpose and replaced in place when preferences change, never appended to. `communication.md` and `scheduling.md` auto-load every session.
- **`knowledge/documents/`** — local-only vault for scans and PDFs; only `_index.md` is tracked.
- **`.claude/skills/`** — `onboarding` (name the assistant, build and grow the wiki), `memory` (wiki operations + wrap-up), `debugging-discipline`, `multilateral-search`, `meeting-ingestor` (audio → transcript → memory), `delegate` (hand bulk work to a secondary agent, explicit request only), `humanizer` (strip AI-writing tells; third-party, included as-is). **`.agents/skills/`** mirrors them for Antigravity.
- **`.claude/hooks/`** — `session-start.sh` loads the session buffer, protocols, identity and wiki map under a byte cap, and flags first run and unwrapped work. `pre-tool-use.py` is a safety gate: it asks before force-pushes, hard resets, recursive deletes and live email/message sends, and blocks inline git-identity overrides. It needs `python` on PATH.
- **`logs/`** — `_session.md` (memory operations buffer) and `YYYY-MM-DD.md` day logs. **`projects/`** — scoped project workspaces. **`.tmp/`** — gitignored scratch.

## Integrations

Prefer what your Claude account already has: enable Gmail, Google Calendar or Google Drive at claude.ai → Settings → Connectors and they appear in Claude Code. For anything else, copy `.mcp.json.example` to `.mcp.json` (gitignored) and fill in your own credentials, or add a server with `claude mcp add`.

## Design notes

- **Lean hot wiki, not an archive.** The wiki holds only what's currently useful. Git history is the archive — resolved threads and stale dumps get deleted, not accumulated.
- **Prose-first memory.** Entities are narrative paragraphs with inline wikilinks, not bullet-point databases.
- **Protocols are not memory.** Behavior rules live in `knowledge/protocols/` and get replaced in place; the memory agent can't write there.
- **Domain isolation.** `work/` and `personal/` never cross-link.
- **Wrap-up commits only this session's files**, so parallel sessions don't sweep each other's work into a commit.
- **Model.** `.claude/settings.json` defaults to Sonnet, which goes much further on a Pro plan's usage limits. Switch with `/model` when a task needs more.
