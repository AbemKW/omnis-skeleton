---
name: memory
description: Store, recall, forget, or clean up facts in the principal's Omnis memory wiki. Use when the user says "remember this", "forget X", "log this", "clean up memory", or shares an article/transcript/paper to ingest. Use to recall context — "what do we know about X", questions about a person/project/decision, or general check-in / session-start context gathering. Also trigger proactively (without being asked) whenever a task/follow-up is completed or newly opened, infrastructure is added/moved/reconfigured, a decision is made, a new person/project/entity enters context, or an active thread's status changes (including resolving one). Also use when the user says "wrap up", "let's wrap up", "end the session", "done for today", or "closing out" — that runs WRAP-UP for this session.
---

# Memory

## What this is

Omnis's memory wiki lives at `knowledge/_Memory/`, managed by a dedicated memory agent (a librarian, not an advisor — it stores/retrieves/organizes, it does not decide what the main agent should do). Paradigm: **lean hot wiki** — hot files are only what's currently useful; git is the archive. Prune resolved actives, ingested source dumps, and stale Notes rather than hoarding them "just in case."

## The five modes

- **STORE** — create or update wiki entities with durable facts.
- **RECALL** — read wiki pages to answer a question about context (read-only).
- **MAINTAIN** — prune resolved actives, rebuild overviews, lint the wiki, trim the session buffer. Heavy writes.
- **INGEST** — ripple durable facts from a shared article/transcript/paper into entities without leaving a hot source dump.
- **WRAP-UP** — close out this session: store what is durable, write the day's log entry, trim `logs/_session.md`, commit only this session's files, push. See [WRAP-UP](#wrap-up).

## When to dispatch

**Proactive by default for durable changes** — dispatch STORE in the background immediately, don't ask. Always-proactive triggers:
- A task or follow-up was completed or newly opened
- Infrastructure was added/moved/renamed/reconfigured
- A decision was made
- A new person, project, or entity entered context
- An active thread's status changed — including **resolved → delete the active file** after folding durable facts into a permanent entity
- The user said "remember this", "forget X", or "log this"

A style/tone preference correction is a **protocol change, not a STORE**. Governing text lives at `knowledge/protocols/`, outside the memory agent's scope. Edit the relevant protocol file directly, in place, on the **first** correction — replace the stale line, don't append. Only dispatch a STORE if the correction also produced a durable fact or reasoning trail worth keeping as narrative.

If unsure whether something is durable: store a tight fact into an existing entity, or skip it. Don't invent new active threads for one-off noise — ephemeral, single-date logistics (an appointment, a one-off errand) belong in an `active/` thread, never folded into a durable identity/domain entity, per the Boundary Separation rule in CLAUDE.md.

Other triggers:
- **Need context about a topic / person / project / "what do we know about X"** → RECALL
- **Session start** → recall open active threads. If the briefing has a `## ⚠ Unwrapped work` block, an earlier session ended without a wrap-up: offer WRAP-UP for those files. If `logs/_session.md` looks large/old, also dispatch a background MAINTAIN
- **"Wrap up", "let's wrap up", "end the session", "done for today"** → WRAP-UP (foreground)
- **"Clean up memory"**, or a bloated `logs/_session.md`, or a pile of resolved actives → MAINTAIN (background) — don't wait to be asked
- **"Forget X"** → STORE (delete the entity)
- **User shares an article/transcript/paper** → INGEST (entity updates only, no hot source dump)
- **"Ingest this"** → INGEST (foreground)

Never manually read/write memory files for routine ops yourself — always dispatch via this skill. Exception: explicit harness/prune work the principal directly requested.

## Dispatch mechanics

- **Always `model: "sonnet"`** for every memory-agent dispatch, all modes. Do not use `haiku` — a weaker model following imperfect ad-hoc instructions is how real miscategorizations happen (an ephemeral appointment filed as durable prose instead of an active thread).
- **STORE**: runs via the `Agent` tool. Foreground when the user explicitly asked ("remember this"); background (`run_in_background: true`) when proactive.
- **RECALL**: runs via the `Agent` tool, read-only. Multiple independent recalls can be dispatched in parallel.
- **MAINTAIN**: background, heavy writes — don't block on it.
- **INGEST**: foreground when the user says "ingest this"; otherwise treat like a proactive background STORE.
- **WRAP-UP**: foreground. The push waits on its commit.
- Payloads: give the dispatched agent enough context to do the job — not the whole wiki.
- **Always put the absolute workspace root in the payload** (`Workspace root: <absolute path>`). Without it, relative `logs/` paths land in the wrong folder.
- **Always put the current time in the payload** (run `date "+%Y-%m-%d %H:%M"` first). Without it, agents invent session-buffer timestamps.

## How to invoke — hard quote-gate

Spawn via the `Agent` tool with `subagent_type: general-purpose`, `model: sonnet`.

**Before every dispatch, read `agents/memory-agent.md` in full and pass its complete, unmodified text as the system-prompt/payload** — appended with only the mode (STORE/RECALL/MAINTAIN/INGEST/WRAP-UP) and the call-specific details (subject, source path, task context). **Never paraphrase, summarize, or hand-compose a substitute for this file's contents.** That file owns all the mechanics of how the modes execute, wiki file formats, wikilink syntax, and the wiki directory structure — including its search-before-write mandate and temporal-integrity rules. Do not restate any of that here; read the file itself.

## WRAP-UP

Closes out **this session only**. Parallel sessions may share the checkout, so wrap-up never commits work this session didn't do.

1. **Build the brief from your own context, not from git.**
   - Session summary: what was done, decisions, tasks completed or opened, active-thread status changes, new people or entities, and any durable fact not yet stored.
   - Session manifest: every repo file this session changed, meaning your own edits plus files named in your subagents' reports. `git status` only tells you which of those are still uncommitted. Never add a file to the manifest because `git status` lists it.
2. **Dispatch the memory agent in WRAP-UP mode** with the brief (foreground, quote-gate above). It stores, writes the day's log entry, trims `logs/_session.md`, and commits the wiki and `logs/` files.
3. **Commit the rest yourself.** Uncommitted manifest files outside the wiki and `logs/` go in with the local git config and a pathspec: `git add -- <paths>`, then `git commit -m "session(wrap-up): <what>" -- <paths>`. Never commit inside a nested repo under `projects/` (one with its own `.git`); list it in the report if it has uncommitted changes.
4. **Push.** `git push`. If the push is rejected or `index.lock` is still there after one retry, stop and report. Never force-push or rebase.
5. **Report**: what was stored, the log entry, commit hashes, the push result, and anything skipped.

When a `## ⚠ Unwrapped work` block triggers WRAP-UP, the original session's context is gone: use the listed files as the manifest and their diffs as the brief.

## See also

- `agents/memory-agent.md` — the memory agent's own system prompt: everything operational lives there, not here
- `knowledge/_Memory/_overview.md` — current map of the memory wiki
