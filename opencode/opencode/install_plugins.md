# Plugin Installation (global: ~/.config/opencode/)

## Standard plugins (install via opencode)
```sh
opencode plugin opencode-devcontainers -g
opencode plugin opencode-handoff -g
opencode plugin cc-safety-net -g
opencode plugin opencode-snip -g
```

## Plugins with broken prepare scripts (oh-my-opencode-slim, opencode-mem)
These have `prepare: bun run build` in package.json but ship pre-built `dist/`. The build fails because source files are excluded from the npm tarball. Install manually skipping the build:

```sh
npm pack oh-my-opencode-slim --pack-destination /tmp
npm pack opencode-mem --pack-destination /tmp
for pkg in oh-my-opencode-slim opencode-mem; do
  mkdir -p ~/.cache/opencode/packages/${pkg}@latest
  tar xzf /tmp/${pkg}-*.tgz -C ~/.cache/opencode/packages/${pkg}@latest --strip-components=1
  npm install --prefix ~/.cache/opencode/packages/${pkg}@latest --ignore-scripts
done
```

Then add to `~/.config/opencode/opencode.json`:
```json
"plugin": ["oh-my-opencode-slim", "opencode-devcontainers", "opencode-handoff", "opencode-mem", "cc-safety-net", "opencode-snip@latest"]
```

## MCP servers
- `web-forager`: `uvx --python ">=3.10,<3.14" web-forager serve`
- `serena`: run as daemon first: `serena start-mcp-server --context agent --daemon --daemon-port 8765 --auto-register`
- Disable `websearch` (duckduckgo tool, not real MCP): rename to `websearch.disabled`

## Skills
Symlink from `~/Projects/ai/vagvaz_skills/` into `.opencode/skills/`:
```sh
ls -d ~/Projects/ai/vagvaz_skills/*/skills/*/ | xargs -I{} ln -sfn {} .opencode/skills/
```

## Config decisions
- web-forager MCP → Oracle agent in oh-my-opencode-slim.json
- DCP skipped for now
- oh-my-opencode-slim preset: switch to `opencode-go` (models match local ollama setup) or update model names
- snip CLI binary must be in PATH (~/.local/bin/snip)
