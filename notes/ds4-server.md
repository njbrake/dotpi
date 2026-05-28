# Running ds4-server on the Mac Studio

ds4-server is the local LLM backend that pi/deepseek talks to. We run it
directly with no extension-managed lifecycle (see top-level `README.md`).

## Launch command

```bash
caffeinate -i ./ds4-server \
  --power 70 \
  --ctx 200000 \
  --kv-disk-dir /tmp/ds4-kv \
  --kv-disk-space-mb 8192 \
  --host 0.0.0.0 \
  > server_logs.log
```

Flag breakdown:

| Flag | Purpose |
|---|---|
| `caffeinate -i` | Prevent idle sleep while the server runs. The Mac Studio is headless; without this it will sleep on long idle gaps. |
| `--power 70` | Server power budget. Trades throughput for thermals/fan noise. |
| `--ctx 200000` | Server-side context limit. Must exceed pi's `contextWindow` (150k in `models.json`) plus margin for end-of-turn overshoot. See "Why ctx is bigger than pi's contextWindow" below. |
| `--kv-disk-dir /tmp/ds4-kv` | On-disk KV cache directory. |
| `--kv-disk-space-mb 8192` | KV cache budget on disk. |
| `--host 0.0.0.0` | Bind all interfaces so pi sandboxes on other machines can reach the server. |

stdout/stderr redirect to `server_logs.log` in the working directory. Tail
that file if a session looks stuck and you want to know whether the server
is actively serving a request.

## Why ctx is bigger than pi's contextWindow

`models.json` declares `contextWindow: 150000`. Pi triggers auto-compaction
when `contextTokens > contextWindow - reserveTokens`. With the default
`reserveTokens=16384`, the compaction trigger fires at ~133.6k.

But the check runs at `agent_end`, not mid-turn (see
`pi-coding-agent/dist/core/agent-session.js`, "Track assistant message for
auto-compaction (checked on agent_end)"). A single long turn with many big
tool outputs (e.g. many bash invocations dumping large stdout) can push
context well past 150k before pi gets a chance to compact. The compact
request itself then exceeds the server's `--ctx` limit and pi loops on
retries, never recovering.

200k on the server gives ~50k of headroom for end-of-turn overshoot. Pi's
auto-compaction behavior is unchanged: it still triggers at ~133.6k, the
status bar still reports `150k (auto)`. The server just stops refusing the
oversized compact request when overshoot happens. Tested 2026-05-28: a
stuck deepseek session at `150054/150000` recovered immediately on the
next retry after the server was restarted at `--ctx 200000`.

## Restart

ds4 is single-stream. An aborted context-heavy request can still occupy
the server for 30+ seconds after the client disconnects (see
`supervision.md`). On restart, give the previous process a moment to exit
before bringing the new one up, or you may see "address in use" or stale
inference on the first request.

```bash
# Stop existing
pkill -f ds4-server

# Confirm port is free
lsof -iTCP:8000 -sTCP:LISTEN

# Relaunch with the command above
```
