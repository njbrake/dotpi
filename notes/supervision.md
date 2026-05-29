# Supervising pi agents with Agent of Empires

We do not let pi (driving DeepSeek V4 Flash via ds4-server) run unsupervised. Instead, an orchestrating agent watches the work, sends corrective steering when needed, and validates closing actions. [Agent of Empires](https://github.com/agent-of-empires/agent-of-empires) (`aoe`) is the connective tissue.

## Topology

```
┌──────────────────────────┐
│  Orchestrator (claude)   │ ← human gives high-level goals
│  in a "monitor" session  │
└──────────┬───────────────┘
           │ aoe send / aoe session capture / gh CLI / git
           ▼
┌──────────────────────────┐
│  aoe                     │ ← session manager (tmux + docker)
└──────────┬───────────────┘
           │ docker exec / tmux pane attach
           ▼
┌──────────────────────────┐
│  pi in an aoe sandbox    │ ← driving deepseek-v4-flash via ds4-server
│  one container per task  │
└──────────────────────────┘
```

Each task gets its own aoe session, which means its own tmux pane, its own docker container, its own pi process, and its own git worktree mounted at `/workspace/...`. Sessions persist across orchestrator restarts.

## Commands the orchestrator uses

| Goal | Command |
|---|---|
| Start a new session with a worktree | `aoe add <name> <branch>` |
| List active sessions | `aoe list` |
| Send a prompt or steering to an agent | `aoe send <session> "<text>"` |
| Read what's on screen | `aoe session capture <session>` |
| Restart a stuck pi process | `aoe session restart <session>` |
| Stop the agent process (keeps container) | `aoe session stop <session>` |

`aoe send` queues a message while the agent is working ("Steering: ..." appears below the screen). It delivers when the agent finishes its current turn.

## The supervision loop

1. **Orchestrator delegates** a bounded task to a specific aoe session via `aoe send`. The prompt is self-contained: issue number, repo, constraints, which skill to use.
2. **Orchestrator monitors** with a `Monitor`-tool script that polls `aoe session capture` for state transitions (working / idle). Polling interval is 30-45 s; the orchestrator does not watch the screen frame by frame.
3. **Orchestrator intervenes only when necessary** — silent failures, context budget approaching exhaustion, the agent confidently going down the wrong path. Otherwise let the agent work.
4. **Orchestrator reviews** the agent's output before any GitHub-visible closing action.
5. **The agent closes its own loop.** Merging, pushing, posting comments — these are the delegated agent's responsibility, not the orchestrator's. (See `feedback-delegate-full-loop-to-deepseek` in the orchestrator's memory.)

## Failure modes worth knowing

- **Stale session jsonl auto-resume.** `aoe session restart` does NOT clear pi's session history. To force a truly fresh start, archive the jsonl in `~/.pi/sandbox/agent/sessions/--<encoded-path>--/` before restarting (rename `.jsonl` to `.jsonl.archived-<ts>.bak`).
- **Sandbox config vs host config divergence.** Pi inside the aoe sandbox reads from `~/.pi/sandbox/agent/`, NOT `~/.pi/agent/`. Symlinks across the mount boundary do not resolve in the container. The `install.sh` in this repo handles the host side; sync to sandbox by copying (not symlinking).
- **Multi-line bash commands silently no-op.** Pi's DSML parser does not handle newlines inside `<｜DSML｜parameter>` values. The model emits, pi renders as raw text, agent goes idle thinking the turn finished. Mitigation: APPEND_SYSTEM rule forces single-line bash commands. Real fix is upstream in pi (filed at earendil-works/pi#3712).
- **Orphaned ds4-server requests block new ones.** ds4 is single-stream; an aborted context-heavy request can still occupy the server for 30+ s after the client disconnects. If a new `aoe send` returns immediately but the agent does not start working, the server may still be churning on the prior request.

## Sandbox details

aoe sandboxes are Docker containers based on `ghcr.io/njbrake/aoe-dev-sandbox`. Each container:

- Mounts the host worktree at `/workspace/<path>` via bind mount
- Mounts `~/.pi/sandbox/` at `/root/.pi` so pi config is shared across sandboxes
- Has its own `node_modules`, `.venv`, and `target` as ephemeral docker volumes (survive restarts, do not pollute the host)

See [agent-of-empires](https://github.com/agent-of-empires/agent-of-empires) for the full config schema, profile management, and hooks.

## When supervision can wind down

The point of this scaffolding is to teach pi/deepseek to operate without it. Each supervision incident is a data point for a SKILL.md or APPEND_SYSTEM rule update. Over time, the orchestrator should be doing less observation and more end-of-task review.
