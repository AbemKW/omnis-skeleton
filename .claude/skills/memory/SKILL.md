---
name: memory
description: Store, recall, forget, or clean up facts in the principal's Omnis memory wiki. Use when the user says "remember this", "forget X", "log this", "clean up memory", or shares an article/transcript/paper to ingest. Use to recall context — "what do we know about X", questions about a person/project/decision, or general check-in / session-start context gathering. Also trigger proactively (without being asked) whenever a task/follow-up is completed or newly opened, infrastructure is added/moved/reconfigured, a decision is made, a new person/project/entity enters context, an active thread's status changes (including resolving one), or the user corrects a style/tone preference for the first time.
---

# Memory

## What this is

Omnis's memory wiki lives at `knowledge/_Memory/`, managed by a dedicated memory agent (a librarian, not an advisor — it stores/retrieves/organizes, it does not decide what the main agent should do). Paradigm: **lean hot wiki** — hot files are only what's currently useful; git is the archive. Prune resolved actives, ingested source dumps, and stale Notes rather than hoarding them "just in case."

## The four modes

- **STORE** — create or update wiki entities with durable facts.
- **RECALL** — read wiki pages to answer a question about context (read-only).
- **MAINTAIN** — prune resolved actives/source dumps, rebuild overviews, lint the wiki. Heavy writes.
- **INGEST** — ripple durable facts from a shared article/transcript/paper into entities without leaving a hot source dump.

## When to dispatch

**Proactive by default for durable changes** — dispatch STORE in the background immediately, don't ask. Always-proactive triggers:
- A task or follow-up was completed or newly opened
- Infrastructure was added/moved/renamed/reconfigured
- A decision was made
- A new person, project, or entity entered context
- An active thread's status changed — including **resolved → delete the active file** after folding durable facts into a permanent entity
- A style/tone preference correction — store to `knowledge/_Memory/preferences/` on the **first** correction
- The user said "remember this", "forget X", or "log this"

If unsure whether something is durable: store a tight fact into an existing entity, or skip it. Don't invent new active threads for one-off noise — ephemeral, single-date logistics (an appointment, a one-off errand) belong in an `active/` thread, never folded into a durable identity/domain entity, per the Boundary Separation rule in CLAUDE.md.

Other triggers:
- **Need context about a topic / person / project / "what do we know about X"** → RECALL
- **Session start** → recall open active threads; if `_session.md` looks large/old, or the active-thread count exceeds ~7 (the stated cap), also dispatch a background MAINTAIN
- **Session wrap-up** → handled proactively in-band by the main agent when tasks or active threads conclude
- **"Clean up memory"**, or an orphaned/bloated `_session.md`, or a pile of resolved actives → MAINTAIN (background) — don't wait to be asked
- **"Forget X"** → STORE (delete the entity)
- **User shares an article/transcript/paper** → INGEST (entity updates only, no hot source dump)
- **"Ingest this"** → INGEST (foreground)

Never manually read/write memory files for routine ops yourself — always dispatch via this skill. Exception: explicit harness/prune work the principal directly requested.

## Dispatch mechanics

- **Always `model: "sonnet"`** for every memory-agent dispatch, all modes. Do not use `haiku` — a weaker model following imperfect ad-hoc instructions is how real miscategorizations happen (an ephemeral appointment filed as durable prose instead of an active thread); `sonnet` is worth the cost for judgment calls this consequential.
- **STORE**: runs via the `Agent` tool. Foreground when the user explicitly asked ("remember this"); background (`run_in_background: true`) when proactive.
- **RECALL**: runs via the `Agent` tool, read-only. Multiple independent recalls can be dispatched in parallel.
- **MAINTAIN**: background, heavy writes — don't block on it.
- **INGEST**: foreground when the user says "ingest this"; otherwise treat like a proactive background STORE.
- Payloads: give the dispatched agent enough context to do the job — not the whole wiki.

## How to invoke — hard quote-gate

Spawn via the `Agent` tool with `subagent_type: general-purpose`, `model: sonnet`.

**Before every dispatch, read `knowledge/_Memory/_agent-prompt.md` in full and pass its complete, unmodified text as the system-prompt/payload** — appended with only the mode (STORE/RECALL/MAINTAIN/INGEST) and the call-specific details (subject, source path, task context). **Never paraphrase, summarize, or hand-compose a substitute for this file's contents.** That file owns all the mechanics of how STORE/RECALL/MAINTAIN/INGEST actually execute, wiki file formats, wikilink syntax, and the wiki directory structure — including its own search-before-write mandate and temporal-integrity rules (future-dated facts belong in active threads, not durable prose) that exist specifically to prevent the kind of miscategorization this gate is protecting against. Do not restate any of that here; read the file itself for anything beyond this dispatch layer.

## See also

- `knowledge/_Memory/_agent-prompt.md` — the memory agent's own system prompt: wiki file formats, wikilink syntax, RECALL budget, correction handling, commit mechanics, domain isolation — everything operational lives there, not here
- `knowledge/_Memory/_overview.md` — current map of the memory wiki
