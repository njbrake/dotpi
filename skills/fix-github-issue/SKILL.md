---
name: fix-github-issue
description: Fix a github issue and create a PR
---

# Fix GitHub Issue Skill

Fix a GitHub issue by creating a branch, implementing the fix, and opening a PR.

## Usage

/fix-github-issue

## Steps

1. **Fetch the issue** — Use `gh issue view <number> --json title,body,labels,comments` to get full context. Assign the ticket to yourself so that people know you're working on it. (If it's already assigned to someone, you should raise this back to me, don't take the ticket from them)

2. **Read project instructions** — Read `AGENTS.md` (and any subdirectory `AGENTS.md` referenced) to understand build commands, conventions, and Definition of Done checks.

3. **Understand the code** — Read all files referenced in the issue. If the issue describes a pattern that should already exist elsewhere (e.g. "ChatPanel does X correctly"), read that file too to understand the target pattern.

4. **Create a branch** — Branch from `main` with a descriptive name: `fix/<short-slug>` for bugs, `feat/<short-slug>` for features. You'll want to make sure you fetch the latest on main first so that you branch off the newest commit.

5. **Implement the fix** — Make the minimal change that addresses the issue. Follow existing patterns in the codebase. Don't refactor surrounding code.

6. **Write a test** — Bug fixes must include a test that reproduces the bug and verifies the fix. If an existing test file covers the component/module, add the test there; otherwise create a new test file matching existing test patterns. The test should fail without the fix and pass with it.

7. **Run all Definition of Done checks** — Run every check listed in `AGENTS.md` under "Definition of Done".

8. **Commit** — Write a clear commit message: imperative subject line, body explaining *why*, include `Fixes #<number>`. Add the `Co-Authored-By: DeepSeek V4 Flash <noreply@deepseek.com>` trailer.

9. **Confirm with user** — Before pushing, present the user with a summary of the changes: files modified, what was changed and why, and test results. Wait for explicit user approval before proceeding. Do not push or create a PR until the user confirms.

10. **Push and open PR** — Push with `-u`, create PR via `gh pr create`.
   - **Before writing the body**, check for a PR template: look for `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, or a `.github/PULL_REQUEST_TEMPLATE/` directory. Use `ls .github/` to find it.
   - **If a template exists**, read it and use it as the PR body structure. Fill in every section from the template with context from the issue and your changes. Do not skip or rearrange sections. Check any applicable checkboxes.
   - **If no template exists**, use this fallback format: `## Summary` (bullet points of what changed), `## Test plan` (checklist of verification steps).
   - Always include `Fixes #<number>` in the body to auto-close the issue.
   - End the PR body with the agent identification footer (see global APPEND_SYSTEM rule).

11. **Self-review the PR using `/self-review-pr`** — Invoke that skill on the PR you just opened. It enforces the breadth check (does the same bug exist in other call sites?) and the test-coverage check (sibling test files for every modified source file) that are easy to miss when reviewing only the diff. Push a fixup commit for any high-confidence finding, then iterate until checks pass.

## Key Principles

- **Read before writing** — Always read the files you're about to change and any files referenced in the issue.
- **Minimal fix** — Only change what's necessary. Don't add improvements, refactors, or extra error handling beyond the scope.
- **Match existing patterns** — If the fix exists elsewhere in the codebase (the issue often says so), copy that pattern exactly.
- **All checks must pass** — Never open a PR with failing lint, types, or tests.
- **One concern per PR** — Don't bundle unrelated changes.
