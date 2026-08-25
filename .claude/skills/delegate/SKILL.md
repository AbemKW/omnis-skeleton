---
name: delegate
description: Hand a token-heavy implementation task off to a secondary coding agent (e.g. Antigravity / `agy`) as a subprocess subagent, to save Claude's own token budget. Use only when the user explicitly says "delegate" or invokes `/delegate` — never on Claude's own judgment. Best for tasks where the spec is already fully resolved (no ambiguity left) and the work itself is bulk/mechanical: large or repetitive multi-file edits, boilerplate, long mechanical iteration loops. Start with extremely simple tasks and grow scope as it proves out.
---

# Delegate

Claude Code's usage is limited and expensive relative to its intelligence. If you have access to a cheaper/higher-limit coding agent (this skill assumes Antigravity's `agy`, Gemini-backed, but adapt to whatever's available), this skill offloads token-intensive *implementation* work to it as a subagent — the same pattern the `Agent` tool uses for in-process subagents (isolated context, one self-contained task, dispatched, reviewed) — to save Claude's tokens for judgment-heavy work.

**Claude Code-only.** Doesn't apply when the secondary agent is the active driver — there's no cheaper engine to delegate to from there.

**Trigger — explicit only.** Fires only when the user explicitly says "delegate" (or `/delegate`). No automatic heuristic-based triggering by Claude's own judgment — this is deliberately narrow; grow scope only as it proves out in use, not by inferring intent.

**Accepted tradeoff — read before using**: `--dangerously-skip-permissions` gives a dispatched run live access to whatever MCP servers are configured, with no interactive confirmation gate. There is no per-dispatch MCP toggle (config is global, not per-project) and no `--sandbox`/read-write task-type restriction in this design. The guardrail is spec discipline, not a technical control: **only hand the secondary agent a task that is fully and explicitly laid out — it will not do anything Claude didn't already describe.** Never delegate an underspecified or open-ended task.

## Mechanism

One dispatch, one worktree, review the diff (never the full transcript), continue-in-conversation on corrections:

1. **Isolate**: `git worktree add .claude/worktrees/agy-<task-slug> -b agy/<task-slug>`. Reuses the repo's existing worktree path convention (excluded via `.git/info/exclude`) — but as a plain `git worktree add`, not any harness worktree tool, since that tool moves the *calling* session's own cwd, not a target directory for a `Bash` subprocess.

2. **Dispatch** via `Bash` (`run_in_background: true` for anything non-trivial), cwd = that worktree path (so the secondary agent inherits `AGENTS.md` governance automatically):
   ```
   agy -p "<self-contained task: goal, files in scope, constraints, acceptance criteria>" \
       --add-dir "<absolute path to the worktree>" \
       --model <secondary-model>-<low|medium|high> \
       --output-format json \
       --dangerously-skip-permissions \
       --print-timeout 10m
   ```
   **`--add-dir <absolute worktree path>` is mandatory, not optional.** `agy --print` does not reliably use the invoking process's OS working directory as its project root — it resolves its own root from persisted/internal state. `cd`-ing into the worktree before the dispatch does nothing for its own path resolution; only `--add-dir` actually points it at the isolated tree. Skipping this flag silently defeats the isolation this skill exists to provide. (Verify this behavior against whatever secondary CLI you're actually using — it may differ.)

   Vary the effort/model-tier suffix by task weight — `low` for trivial/high-volume grunt work, `medium` as the default, `high` for larger delegated builds that still don't need Claude's own judgment. Capture the conversation ID from the JSON result (`--output-format json`).

3. **Review**: read the git diff in the worktree plus the JSON result summary — never the full conversation transcript (that's the token-saving point). Apply the same rigor as `/code-review` before treating it as done. Never merge output unreviewed.

4. **If wrong**: re-dispatch as a follow-up turn in the *same* conversation:
   ```
   agy -p "<exact fixes to make>" --conversation <id> --add-dir "<same absolute worktree path>" --model <secondary-model>-<tier> --output-format json --dangerously-skip-permissions --print-timeout 10m
   ```
   `--add-dir` on every follow-up too — the same reasoning as step 2, it's per-invocation, not sticky across conversation resumes.
   Use an explicit `--conversation <id>`, not "continue most recent" — that's ambiguous once multiple delegated runs are in flight. Give the exact fixes needed, not a vague "try again." Cap at 2 correction rounds — if still wrong after that, stop looping and have Claude finish the task directly instead of continuing to spend review-token budget on a task that wasn't as well-specified as assumed.

5. **If good**: merge into the target branch, then remove the worktree (`git worktree remove`).

6. **Parallelizable**: multiple delegated dispatches can run concurrently, each in its own worktree/branch, zero collision.
