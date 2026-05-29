# Monitoring an aoe session from the orchestrator

When the orchestrator (Claude Code) delegates a task to a pi agent via
`aoe send`, it should not stare at the screen. Instead, it arms a
background watcher that polls `aoe session capture` once a minute and
emits a chat notification only on actionable events. The pattern below
is what `supervision.md`'s "monitor the agent" step actually looks like
in practice.

This file is an orchestrator-side artifact: it documents what Claude
Code does, not what pi does. It lives in pi-config because the
supervision loop is the topic the rest of `notes/` is about.

## The polling script

Claude Code's `Monitor` tool takes a bash command. Each line of stdout
becomes a chat notification, so the script must be selective. Default
template:

```bash
tick=0
strip_ansi() { sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g'; }
while true; do
  tick=$((tick+1))
  raw=$(aoe session capture <session> 2>/dev/null | strip_ansi)
  if [ -z "$raw" ]; then echo "[tick $tick] capture empty"; sleep 60; continue; fi

  last_cmd=$(echo "$raw" | grep -E '^\s*\$ ' | tail -1 | sed -E 's/^\s*\$ //' | cut -c1-140)

  # Destructive ops: only flag when matched on a $-prompted shell line,
  # so my own steering messages echoed onto the screen do not fire alerts.
  alert=$(echo "$raw" | grep -E '\$ .*git push (-f|--force)[^-]|\$ .*git reset --hard|\$ .*branch -D|\$ .*--no-verify|\$ .*rm -rf /|\$ .*sudo rm|\$ .*gh release delete|\$ .*gh release create|\$ .*gh pr merge.*--admin' | tail -3)

  # Checkpoint phrases the fix-github-issue skill emits at step 9.
  checkpoint=$(echo "$raw" | grep -E -i 'wait(ing)? (for )?(explicit )?(user|your) (approval|confirm)|please confirm|may I proceed|ready to push|Ready to proceed' | tail -2)

  # Milestones (tune per task type, see below).
  done_sig=$(echo "$raw" | grep -E '\$ .*gh pr (create|merge) ' | tail -2)

  # Errors that mean the agent is stuck or the server choked.
  errors=$(echo "$raw" | grep -E -i 'Error: 400 Prompt has|Retry failed after|panic:|gh: command not found|HTTP 5[0-9]{2}' | tail -2)

  if [ -n "$alert" ]; then echo "[tick $tick] DESTRUCTIVE: $alert"; fi
  if [ -n "$checkpoint" ]; then echo "[tick $tick] CHECKPOINT: $checkpoint"; fi
  if [ -n "$done_sig" ]; then echo "[tick $tick] MILESTONE: $done_sig"; fi
  if [ -n "$errors" ]; then echo "[tick $tick] ERROR: $errors"; fi

  # Heartbeat every 5 ticks so silence is not mistaken for liveness.
  if [ $((tick % 5)) -eq 1 ]; then echo "[tick $tick] heartbeat | last: ${last_cmd:-<idle>}"; fi
  sleep 60
done
```

Call with `persistent: true` and `timeout_ms: 3600000`. Stop with
`TaskStop` when the delegated task completes.

## What gets flagged and why

| Category | Why |
|---|---|
| **DESTRUCTIVE** | Unauthorized prod actions or branch-protection bypasses. Hard list: force push (not `--force-with-lease`), hard reset, branch delete, `--no-verify`, `rm -rf /`, `sudo rm`, release delete, release create from inside a task that did not authorize releases, `gh pr merge --admin`. |
| **CHECKPOINT** | `fix-github-issue`'s step 9 pauses for orchestrator approval before push. Catching these phrases means the agent is waiting for a human decision, not stuck. |
| **MILESTONE** | A long-running task crossed a known step (PR opened, PR merged, release tag created). Lets the orchestrator stop polling tighter and switch to the review phase. |
| **ERROR** | Server context blowouts, retry exhaustion, panics, 5xx. These usually need orchestrator action; agent will not self-recover. |
| **heartbeat** | One emission every five ticks with the last shell-prompted command so silence is distinguishable from a stuck process. |

Anything NOT in those buckets is intentionally not emitted. The
supervision threshold rule is: intervene only on destructive ops or
hard failure. Inefficiency is acceptable.

## Regex gotchas

- **Always gate destructive matches on `$ `** (the bash prompt prefix).
  Without that, your own steering messages quoted back onto the screen
  trigger false alerts. This was the largest source of monitor noise
  before the regex was tightened.
- **`git push --force-with-lease` is safe** when used on the agent's
  own PR branch after a rebase. The regex uses `--force[^-]` to allow
  `--force-with-lease` through.
- **Heartbeats can show stale `last_cmd`** when the agent is using pi's
  native `edit` tool (not bash). The grep only sees `$ `-prefixed bash
  commands, so an editing-only stretch reads as `<idle>` even though
  the agent is working. Verify with a direct `aoe session capture` if
  the heartbeat looks frozen for several ticks.

## Per-task-type tweaks

| Task | Milestones to add |
|---|---|
| `fix-github-issue` | default template is correct; `gh pr create`/`gh pr merge` cover both ends. |
| OSS release flow | `gh release create vX.Y.Z`, `notify-premium`, `repository_dispatch`, `gh pr close N`/`gh pr reopen N` for the auto-merge workaround, the bump PR opening and merging. |
| address-review | fixup commits, `gh pr review --comment`, final merge. |

When adding new milestone patterns, keep the `\$ ` prefix gating to
avoid stale-scrollback false positives.

## Between tasks: archive the jsonl

After a task completes and before delegating the next one, archive the
session's jsonl in `~/.pi/sandbox/agent/sessions/--<encoded-path>--/`
(rename the active `.jsonl` to `.jsonl.archived-<YYYYMMDD>-<tag>.bak`)
and `aoe session restart <session>`. Carried-over context from the
previous task biases the agent and risks auto-compact mid-task on the
next run. See `supervision.md`'s "Failure modes worth knowing" section
for the longer note on stale session jsonl auto-resume.
