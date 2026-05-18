# Post-Install Observations

## Installation Notes

### oh-my-opencode-slim
- Installer (`bunx oh-my-opencode-slim@latest install`) generated config at `~/.config/opencode/oh-my-opencode-slim.json`
- Auto-added itself to `opencode.json` plugin array and disabled built-in `explore`/`general` agents
- Generated two presets: `openai` (default active) and `opencode-go`
- Oracle agent had empty `mcps` — added `web-forager` to both presets

### web-forager
- Installed via `uv tool install web-forager` into uv's isolated tool directory
- MCP runs via `uvx` which auto-creates a temp venv — doesn't touch system Python
- Note: Nix-managed Python was a transient issue with `uv pip install --system`. The current system Python (`/usr/bin/python3`) is a standard install, but uv tool/uvx approach is preferred anyway since it's fully isolated

### Serena (vagvaz fork, multi_project branch)
- Installed via `uv tool install --prerelease=allow -p 3.13 .` from local clone
- **Non-editable install** — installed into `~/.local/share/uv/tools/serena-agent/` as a snapshot. Changes to `~/Projects/ai/serena/` won't be reflected unless reinstalled
- For development, switch to editable mode: `cd ~/Projects/ai/serena && pip install -e .`
- Must run as **daemon**, not stdio:
  ```
  serena start-mcp-server --context agent --daemon --daemon-port 8765 --auto-register
  ```
- The MCP endpoint is `http://127.0.0.1:8765/sse`
- OpenCode connects via `"type": "remote"` pointing to that URL
- Dashboard starts on a random port (24282 in this run, not 8080)
- Exposes 28 tools in `agent` context, including `session_init` for project binding
- Auto-generated config at `~/.serena/serena_config.yml` on first start

### Context-Analysis
- Manual copy of `.opencode/` directory — added `command/context.md` and `plugin/context-usage.ts`
- `/context` command available immediately, no npm install needed

### npm plugins (devcontainers, handoff, mem, cc-safety-net, opencode-snip)
- Just added to `opencode.json` plugin array — OpenCode auto-installs on next startup
- `opencode-snip` needs the snip CLI binary (`~/.local/bin/snip`) which was already present at v0.15.0

### Skills (49 total from 3 repos)
- Symlinked from `vagvaz_skills/` submodules into `~/.config/opencode/skills/` (global)
- Conflict resolution applied: `anthropics-` prefix for anthropics, `openai-` prefix for openai
- `openai-docs` had internal collision between `.system` and `.curated` — `.system` won
- mattpocock skills (nested under category dirs like `engineering/diagnose`) flattened with no prefix
- Also includes 2 built-in opencode skills (`codemap`, `simplify`) — 51 total

### websearch MCP
- Was a local tool file at `~/.config/opencode/tools/websearch_duckduckgo.ts`, not an actual MCP server
- Renamed to `.disabled` — effectively disabled

## Config Architecture

The setup spans two config levels:

### Global (`~/.config/opencode/`)
- `opencode.json` — plugins, MCP servers (web-forager + serena), agent config
- `oh-my-opencode-slim.json` — agent orchestration config with per-agent model/skill/MCP assignments
- `config.json` — provider configs (ollama local models)
- `command/context.md` — from context-analysis plugin
- `plugin/context-usage.ts` — from context-analysis plugin

### Plugin Install Bug (opencode plugin command)

Two plugins (`oh-my-opencode-slim`, `opencode-mem`) fail to install via `opencode plugin <name> -g` because:
- Their `package.json` has a `prepare` script that runs `bun run build`
- The source files needed for building (`src/index.ts`) are **excluded** from the published npm tarball (via the `files` field)
- `npm install` runs the `prepare` script → build fails → cache dir left empty

**Fix** (v2 — corrected): Use `npm install` directly with `--ignore-scripts` to create the proper nested structure:

```sh
rm -rf ~/.cache/opencode/packages/<pkg>@latest
npm install <pkg>@latest --prefix ~/.cache/opencode/packages/<pkg>@latest --ignore-scripts
```

This creates the correct structure:
```
<pkg>@latest/
├── package.json        (npm wrapper)
├── node_modules/
│   ├── <pkg>/          ← plugin code here
│   │   ├── package.json
│   │   ├── dist/index.js
│   │   └── ...
│   └── ... (deps)
```

**Why v1 didn't work**: The old method (`npm pack` + `tar xzf` + `npm install --prefix --ignore-scripts`) unpacked the tarball at the root level of the cache dir. OpenCode expects the plugin package to be inside `node_modules/<name>/` (standard npm layout). The nested structure is only created when npm itself installs the package via `npm install <pkg> --prefix <dir>`.

## Potential Issues / Watch Items

1. **Serena daemon lifecycle** — Must be started manually before OpenCode. No auto-start mechanism. If OpenCode starts before Serena, MCP connection fails silently.
2. **oh-my-opencode-slim preset** — Switched to `custom` preset (deepseek-v4-flash, deepseek-v4-pro, kimi-k2.5, qwen3.5-plus). Fixes model mismatches and replaces Librarian's `websearch` with `web-forager`.
3. ~~**Librarian references `websearch` MCP**~~ — Fixed: replaced with `web-forager` in all presets.
4. **snip + opencode-snip interaction** — Snip CLI v0.15.0 is installed. opencode-snip plugin auto-prefixes commands with `snip`. Note: `snip` doesn't handle variable assignments or complex shell constructs well — use script files for those.
5. **DCP skipped** — Context pruning not active. Long sessions may hit context limits without compression.
6. ~~**Skills are project-level**~~ — Fixed: skills now installed globally in `~/.config/opencode/skills/`.
