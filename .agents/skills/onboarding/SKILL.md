---
name: onboarding
description: Name the assistant and interview the principal to build or grow their memory wiki (knowledge/_Memory/). Use on a completely empty wiki (first run), AND on an ongoing basis whenever memory looks thin — a domain overview is still a placeholder, a new life area comes up with nowhere to live, or it's been a while since a memory checkup. Onboarding is never "done once" — invoke this any time filling in memory would help, not just at setup.
---

# Onboarding

## This is not a one-time setup wizard

The wiki is never "finished." Treat onboarding as a recurring conversation, not an installer step:

- **First run** (wiki fully empty): name the assistant, full interview, scaffold everything.
- **Ongoing** (wiki partially built): whenever you notice a gap — a domain `_overview.md` still reads as a placeholder, the principal mentions a person/project/commitment with nowhere to go, or a domain that should exist doesn't — run a **lightweight, targeted** version of this skill for just that gap. Don't wait to be asked.
- **Periodic checkup**: if it's been a while since anything outside `active/` changed (check `git log -- knowledge/_Memory/`), or the principal seems to be repeating context you should already have, propose a short memory checkup: 3-5 questions about what's changed.

## First run

The session-start hook prints `## ⚠ First run` while `knowledge/_Memory/_overview.md` is still the shipped placeholder. Do this before any other work. Keep it conversational — a few questions at a time, never a 20-item form.

### 0. Name the assistant

Ask what the principal wants to call their assistant (they may already have a name). Then rename it everywhere it is the assistant's name — `CLAUDE.md`, `AGENTS.md`, `README.md`, `agents/*.md`, `.claude/skills/*/SKILL.md`, `.agents/skills/*/SKILL.md`, `knowledge/protocols/*.md`: replace `Omnis` with the new name (and `Omnis's` with its possessive). Skip `.claude/skills/humanizer/` (third-party). Show the principal the `git diff --stat`, then commit (`chore: name the assistant <Name>`) with the local git config. From this point on, you are that name.

Also replace "the principal" in the top section of `CLAUDE.md`/`AGENTS.md` with the principal's first name, so the identity reads personally ("Nova is Sam's personal intelligence system").

### 1. Identity

Name, what to call them, age/stage, role(s) (student / employee / founder / etc.), where they live, languages, a one-line self-description, and what they most want help with right now. Dispatch a STORE (via the `memory` skill) to create `knowledge/_Memory/identity/<first-last>.md`.

### 2. How the assistant should behave

Tone (blunt / warm / playful), length, formatting, how proactive vs. cautious to be, any hard "never do X" rules. This is governing text, not memory: write it **directly** into `knowledge/protocols/communication.md`, replacing the placeholder lines. If they have a calendar habit worth encoding, fill `scheduling.md` the same way.

### 3. Domains

Walk the placeholder domains in `_overview.md` (`personal`, `academics`, `work`, `research`, `ventures`) and ask which apply. Delete the ones that don't (`git rm -r`). Rename or add domains to fit their life (e.g. a student might want `academics/` plus `competitions/`); a new domain gets `_overview.md`, `people/`, and `active/.gitkeep`. For each surviving domain, ask for 2-3 current facts — people, ongoing threads, near-term deadlines — and STORE them. Deadlines and in-flight work become `active/` threads.

### 4. Tools

Which integrations they'll actually use. Prefer what their Claude account already offers (claude.ai connectors such as Gmail, Google Calendar and Google Drive show up in Claude Code automatically once enabled at claude.ai > Settings > Connectors) over installing MCP servers. For each one in use, add a short section to `knowledge/protocols/tools.md`.

### 5. Close out

Rewrite `knowledge/_Memory/_overview.md` as a short current narrative map linking into whatever got seeded (remove the "Nothing here yet" placeholder line so the first-run banner stops). Then run WRAP-UP via the `memory` skill so everything is committed and pushed.

## Ongoing / targeted mode

When memory is already partially built and you spot a specific gap:

1. Ask only about that gap (don't re-run the full interview).
2. Dispatch the write via the `memory` skill's STORE mode — the format rules live in `agents/memory-agent.md`. Don't hand-edit wiki files yourself.
3. If the gap reveals a whole new domain, create it following the existing domain shape rather than jamming it into an unrelated one.
4. If the gap is about how the assistant behaves, edit the relevant `knowledge/protocols/` file directly, in place.

## Don't onboard into thin air

Never invent facts to fill a gap. If the principal doesn't have an answer yet ("no ventures right now"), record that as the current state — an empty or deleted domain is a valid, honest answer — rather than leaving a stale placeholder that looks unfinished forever.
