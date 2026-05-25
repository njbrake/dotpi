# Global context

Loaded as a user-message context block every session. Project-specific `AGENTS.md` files extend this.

## Environment

- Local LLM backend: ds4-server (DeepSeek V4 Flash) on a Mac Studio
- Pi config: `~/.pi/agent/` (symlinks from `~/pi-config/`)
- Sessions often run inside Agent of Empires sandboxes; host `~/scm/...` ↔ sandbox `/workspace/...`

## Conventions

- Conventional commit prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `ci:`, `chore:`
- No em dashes in code, comments, or user-facing copy — use periods, commas, colons, or pipes
- For `uv`-based projects, DoD is: `uv run pytest -v && uv run ruff check && uv run ruff format --check && uv run ty check --python .venv <paths>`
