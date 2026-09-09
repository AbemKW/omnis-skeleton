---
name: onboarding
description: Interview the principal to build or grow their Omnis memory wiki (knowledge/_Memory/). Use on a completely empty wiki (first run), AND on an ongoing basis whenever memory looks thin — a domain overview is still a placeholder, a new life area comes up with nowhere to live, or it's been a while since a memory checkup. Onboarding here is never "done once" — invoke this any time filling in memory would help, not just at setup.
---

# Onboarding

## This is not a one-time setup wizard

The wiki is never "finished." Treat onboarding as a recurring conversation, not an installer step:

- **First run** (wiki fully empty): full interview, scaffold everything.
- **Ongoing** (wiki partially built): whenever you notice a gap — a domain `_overview.md` still reads as a placeholder, the principal mentions a person/project/commitment with nowhere to go, or a domain that should exist doesn't — run a **lightweight, targeted** version of this skill for just that gap. Don't wait to be asked.
- **Periodic checkup**: if it's been a while since anything outside `active/` changed (check `git log` on `knowledge/_Memory/`), or the principal seems to be repeating context you should already have, propose a short memory checkup: 3-5 questions about what's changed since the wiki was last touched.

The bar for triggering this skill proactively is the same as the memory skill's STORE trigger — if losing this fact would hurt a future session, this skill is how you go get it rather than waiting for it to be volunteered.

## First-run interview

If `knowledge/_Memory/_overview.md` still reads as a bare scaffold (see the placeholder text shipped in this repo), do this before any other work:

1. **Identity** — name, what to call them, their role(s) (student / employee / founder / etc.), one-line self-description. Write to `knowledge/_Memory/identity/`.
2. **Preferences** — tone they want from Omnis, how proactive vs. cautious to be, any hard "never do X" rules. Write to `knowledge/_Memory/preferences/`.
3. **Active domains** — walk the placeholder domain list in `_overview.md` (`personal`, `academics`, `work`, `research`, `ventures`) and ask which actually apply. Delete the ones that don't; for the ones that do, ask for 2-3 current facts (people, ongoing threads, near-term commitments) to seed each `_overview.md`.
4. **Tool integrations** — which MCP servers they'll actually use (email, calendar, finance, etc.) so `.mcp.json` and any permission allowlisting in `.claude/settings.json` match reality instead of copying a stranger's setup.
5. **Rewrite `_overview.md`** as a short current narrative map linking into whatever got seeded, replacing the placeholder text.

Keep this conversational — ask a few questions at a time, not a 20-item form. It's fine to seed a domain thin and grow it later; that's the point of treating this as ongoing.

## Ongoing / targeted mode

When memory is already partially built and you spot a specific gap:

1. Ask only about that gap (don't re-run the full interview).
2. Follow the format rules in `knowledge/_Memory/_agent-prompt.md` (prose-first, wikilinks, domain isolation) — dispatch the actual write via the `memory` skill's STORE mode, don't hand-edit wiki files yourself.
3. If the gap reveals a whole new domain the placeholder list didn't anticipate, create it following the existing domain shape (`_overview.md`, `active/`) rather than jamming it into an unrelated one.

## Don't onboard into thin air

Never invent facts to fill a gap. If the principal doesn't have an answer yet ("no active ventures right now"), record that as the current state — an empty or deleted domain is a valid, honest answer — rather than leaving a stale placeholder that looks unfinished forever.
