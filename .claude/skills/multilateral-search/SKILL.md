---
name: multilateral-search
description: Decompose-dispatch-synthesize technique for answering a question about a codebase or a complex plan. Use when a question about the codebase or a complex plan has multiple independent angles worth investigating in parallel, rather than one linear search.
---

## When to use

The question has 2+ genuinely independent angles — different subsystems, different data sources, or different concerns (e.g. "is this safe to ship" = correctness + performance + security). Skip this for a single-file lookup or anything answerable with one Grep/Read — decomposing a trivial question just adds latency and synthesis overhead for no gain.

## 1. Decompose

Split into 2-5 perspectives that are **independent**: each is answerable without needing another perspective's findings first, and they don't overlap enough that two subagents would re-read the same files to answer the same sub-question. If you can't state a perspective as a standalone question with its own scope, it's not independent — fold it into the closest one instead of forcing a split.

## 2. Dispatch

Each perspective goes to a background subagent (`Agent` tool, `run_in_background: true`, `model: haiku`). These are fresh agents with **no memory of this conversation** — each prompt must be self-contained: state the overall question for context, the specific angle this agent owns, and where to look if you already know (directories, file patterns, prior findings). Ask each to report findings with file:line citations and an explicit confidence level (high/medium/low), not just a conclusion.

Escalate off `haiku` to a stronger model for any single perspective that itself requires multi-step reasoning or judgment calls (e.g. "assess whether this migration is safe") rather than pattern-matching/lookup — haiku is for cheap parallel retrieval, not for the angle that carries the real analytical weight.

## 3. Synthesize

Once all subagents report (or time out — don't block indefinitely; note which angle is missing and flag it as a gap rather than silently dropping it):
- Reconcile contradictions using citation strength, not majority vote — a low-confidence claim with no citation loses to a high-confidence one with file:line.
- Produce one coherent answer, not a stitched-together list of subagent reports. Cite the file:line evidence that backs each claim.
- If two perspectives surfaced conflicting evidence that you can't resolve from what they returned, say so explicitly instead of picking one silently.

## Example

Question: "Is it safe to remove the legacy `auth_v1` module?"
- Decompose: (a) is anything still calling it, (b) does removing it break the migration path for existing sessions, (c) does any config/deploy script reference it.
- Dispatch: three haiku subagents, each told the overall question and its one angle, with instructions to grep/read and cite file:line.
- Synthesize: "(a) found 2 live call sites in `billing/legacy.py:44,112` — not safe to remove yet" beats a generic "probably fine" from another angle with no citation.
