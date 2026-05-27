# pi-config

Personal configuration for [pi-coding-agent](https://github.com/badlogic/pi-mono), tuned for a locally-hosted [DeepSeek V4 Flash](https://github.com/antirez/ds4) backend.

Cloned to `~/dotpi/` and symlinked into `~/.pi/agent/` via `install.sh`. Editing files here edits them live in pi.

## Layout

| File | Symlinks to | Purpose |
|---|---|---|
| `AGENTS.md` | `~/.pi/agent/AGENTS.md` | Global context, loaded as a user-message block every session |
| `APPEND_SYSTEM.md` | `~/.pi/agent/APPEND_SYSTEM.md` | Behavior rules, appended to pi's built-in system prompt |
| `settings.json` | `~/.pi/agent/settings.json` | Pi runtime settings (retry, thinking level) |
| `models.json` | `~/.pi/agent/models.json` | Provider/model registry |
| `skills/` | `~/.pi/agent/skills/` | User-level slash commands |
| `prompts/` | `~/.pi/agent/prompts/` | Reusable prompt templates |

`SYSTEM.md` is deliberately not included; we want pi's defaults intact and only append to them.

Setup tips, host tuning, and supervision workflow notes that aren't part of the live config live in [`notes/`](notes/).

## Install

```bash
git clone git@github.com:njbrake/dotpi.git ~/dotpi
cd ~/dotpi && ./install.sh
```

## Inspiration

Initial config copied from [mitsuhiko/pi-ds4](https://github.com/mitsuhiko/pi-ds4)'s defaults. Diverges where our usage diverges: no extension-managed lifecycle (we run `ds4-server` directly), and tuned for our specific hardware/network setup. See inline comments in `models.json` and `settings.json` for the rationale on individual values.

## See also

- [antirez/ds4](https://github.com/antirez/ds4) — local LLM server
- [mitsuhiko/pi-ds4](https://github.com/mitsuhiko/pi-ds4) — reference pi extension
- [badlogic/pi-mono](https://github.com/badlogic/pi-mono) — pi source
