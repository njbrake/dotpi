---
name: self-review-pr
description: Self-review a PR you just opened. Catch completeness gaps (breadth misses, missing tests) the way a careful maintainer would, not just diff correctness.
---

# Self-Review a PR You Just Opened

Review a PR before handing back to the user. The goal is to catch the things you'd be embarrassed about if a reviewer flagged them next.

Reading the diff alone is not enough. A clean diff can still miss the point of the bug.

## Usage

/self-review-pr [pr-number]

If no PR number is given, default to the most recent PR you opened on the current branch.

## Steps

1. **Restate the goal.** Read the linked issue (or PR description if no issue). Restate the problem in one sentence. If you can't restate it, re-read.

2. **Diff correctness.** For each modified file:
   - Verify the change does what the description claims
   - Check edge cases (empty input, null, single element, fallback paths)
   - For any test you added: confirm it would fail without the fix. Run it against the prior commit if there's any doubt.

3. **Breadth check — the most commonly missed step.** A bug pattern almost always exists in more than one place. Before deciding the PR is complete:
   - Identify the predicate or pattern your fix targets (e.g. `filter(t => t.category === 'domain')`, `await db.execute(insert(X))`, a specific error path).
   - Grep the codebase for that pattern. For each hit not in your diff, ask: *does the same bug exist here?*
   - For every hit that shares the bug: either include it in this PR, or write down explicitly why it is out of scope.
   - "I'll do it in a follow-up" is fine. Silent omission is not. Name every site you considered and chose not to touch.

4. **Test coverage check.** For each modified source file:
   - Does a sibling test file exist (e.g. `ToolsPage.tsx` → `ToolsPage.test.tsx`)?
   - Did you add a test there for the new behavior?
   - If you modified two files and only tested one, the other is a gap. Either add a test or name the gap.
   - Do not dismiss with "uses the same logic, acceptable." Test gaps are gaps — name them, then decide.

5. **Convention scan.** Read 50 lines of context around each diff hunk. Does anything in your diff diverge from the surrounding style (naming, imports, types, helper usage, error handling)? If something looks unusual, ask why.

6. **PR hygiene.** Confirm:
   - PR template followed end to end (no skipped sections, no checkbox theater)
   - `Fixes #N` to auto-close the issue
   - Identification footer present per the global rule
   - Commit message follows conventional commit format
   - Commit has the `Co-Authored-By` trailer per the global rule

7. **Write the verdict.** Use these headings, in this order:

   - **Completeness gaps** — breadth misses, missing tests, missing follow-up notes. If none, write "none."
   - **Bugs** — incorrect logic, edge cases not handled
   - **Convention concerns**
   - **PR hygiene**
   - **Conclusion** — one of:
     - "Clean, ready to merge" (only if all four above are empty)
     - "Fix needed before merge: <list>"
     - "Land as-is, follow-up needed for: <list>"

   For any high-confidence small fix found in steps 2-6, stage it and force-push a fixup commit. Do not invent new requirements the issue did not ask for.

## Honest self-review applies here

[[feedback-honest-self-review]] is the general rule. Specifically for PR self-review:

- Do not soften findings. "Test gap" is not "acceptable." "Missed a third call site" is not "out of scope."
- Lead with what's wrong. If completeness gaps or bugs exist, surface them before any "what works well" prose.
- If you ran the breadth check and found nothing, say so. Silence on an expected step reads as a skipped step.
- Pre-existing test failures are not yours to fix, but they ARE yours to surface — name them so the maintainer doesn't assume the suite is fully green.

## What NOT to do

- Do not post the review to GitHub. The orchestrator or user decides whether and how to comment.
- Do not redo the work. The point is to review the PR, not to re-implement the feature.
- Do not redesign the change. If the design is wrong, name it as one bullet under Conclusion and stop.
- Do not add scope the issue did not ask for. Breadth check fixes related bugs of the same kind; scope creep adds unrelated improvements.
