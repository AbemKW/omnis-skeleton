---
name: debugging-discipline
description: Reproduce-first debugging protocol with parallel root-cause hypotheses. Use whenever debugging a bug, investigating a failure, or proposing a fix for broken behavior.
---

## When to use

For a bug whose cause isn't already obvious from a stack trace, an error message, or a one-line diff. If the traceback points unambiguously at a single line (a typo, an off-by-one, a null the caller obviously forgot to check), just fix it and verify — spinning up 3 hypothesis subagents for a cause you already know wastes time and dilutes the discipline for cases that actually need it.

## 1. Reproduce first

Do NOT propose a fix until the bug is reproduced. "Reproduced" means one of: a failing test, a repro script, or an observed error you triggered yourself — not "this code looks like it would fail." If you can't reproduce it, say so and investigate why before guessing at a fix.

## 2. Parallel hypotheses

Spawn 3 parallel background subagents (`invoke_subagent` with model `flash`), each with a genuinely distinct root-cause hypothesis — not the same cause worded three ways. Each prompt is self-contained (these agents have no memory of this conversation): give the observed symptom, exact repro steps/command, and the one hypothesis to investigate. Ask each to gather evidence for or against its hypothesis (logs, code paths, actual values at runtime) and report a verdict with citations — not to apply a fix.

If two hypotheses come back both plausible, don't average them into a combined fix — pick based on which has actual observed evidence (a traced value, a log line) versus which is merely consistent with the symptom. If none of the 3 pan out, that's a signal to reproduce more carefully or widen the hypothesis set, not to fix the closest-looking one anyway.

## 3. Show the reproducer

Output the failing run (the test failure, the error, the repro script's output) before writing the fix, so the before-state is on record.

## 4. No self-validating tests

The test must fail against the old code and pass only after the fix. A test that passes before you've changed anything doesn't test the bug.

## 5. No root-cause claims without observed confirmation

Don't declare "this was the cause" from reasoning alone — trace the actual log lines, print the actual variable value, or otherwise empirically confirm the mechanism before and after the fix.
