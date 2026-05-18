# OpenCode Memory & Plugin Discussion Summary

## Memory Plugins Compared

### opencode-agent-memory (joshuadavidthomas)
- **Repo**: https://github.com/joshuadavidthomas/opencode-agent-memory
- **Approach**: Letta-style structured markdown blocks with YAML frontmatter
- **Storage**: Global (`~/.config/opencode/memory/*.md`) + Project (`.opencode/memory/*.md`)
- **Tools**: `memory_list`, `memory_set`, `memory_replace`
- **Extra**: Journal with local semantic search (all-MiniLM-L6-v2), block descriptions, read-only blocks, size limits
- **Forgetting**: No dedicated `forget` tool — must `memory_set` to empty string, `memory_replace` with "", or delete the `.md` file manually
- **Per-project**: Actual physical separation — global blocks in `~/.config/opencode/memory/`, project blocks in `$PWD/.opencode/memory/`
- **Activity**: 8 commits, 2 releases, last commit Mar 1 2026, 221 stars, 13 forks
- **Install**: `{ "plugin": ["opencode-agent-memory"] }`

### opencode-plugin-simple-memory (cnicolov)
- **Repo**: https://github.com/cnicolov/opencode-plugin-simple-memory
- **Approach**: Simple CRUD with logfmt entries on disk
- **Storage**: `.opencode/memory/` as daily logfmt files (all per-project, no global)
- **Tools**: `memory_remember`, `memory_recall`, `memory_update`, `memory_forget`, `memory_list`
- **Extra**: Audit logging on forget, typed memories (decision, learning, preference, etc.)
- **Forgetting**: Has dedicated `memory_forget` with audit logging
- **Per-project**: Everything goes to `$PWD/.opencode/memory/`. `scope` is just a logical tag, not a filesystem boundary. No cross-project memory.
- **Activity**: 17 commits, 5 tags, last commit Mar 18 2026, 89 stars, 9 forks
- **Install**: `{ "plugin": ["@knikolov/opencode-plugin-simple-memory"] }`

### opencode-mem (tickernelz) — Recommended
- **Repo**: https://github.com/tickernelz/opencode-mem
- **Approach**: Local vector database (USearch + SQLite), web UI, auto-capture
- **Tools**: Single `memory()` tool with modes: `add`, `search`, `profile`, `list`
- **Extra**: Web UI at port 4747, user profile learning, auto-capture, multi-provider AI, compaction, deduplication
- **Activity**: 55 versions on npm (v2.13.0), 1,409 weekly downloads, very actively maintained
- **Install**: `{ "plugin": ["opencode-mem"] }`

### open-mem (clopca)
- **Repo**: https://github.com/clopca/open-mem
- **Approach**: Background capture + AI compression, SQLite + FTS5 + sqlite-vec + knowledge graph
- **Extra**: 9 memory tools, web dashboard, revision lineage, multi-platform (Claude Code, Cursor, MCP), AGENTS.md generation
- **Activity**: 32 commits, v0.12.0, 16 stars, 1 fork — very early/sophisticated

## Background Agents Plugin

### opencode-background-agents (kdcokenny) — Best option
- **Repo**: https://github.com/kdcokenny/opencode-background-agents
- **Approach**: Claude Code-style async delegation with context persistence
- **Tools**: `delegate(prompt, agent)`, `delegation_read(id)`, `delegation_list()`
- **Activity**: 223 stars, 15 forks, 40 commits, active
- **Install**: OCX (`ocx add kdco/background-agents --from https://registry.kdco.dev`) or manual copy of `src/` to `.opencode/plugin/`
- **Caveat**: Not on npm, only OCX or manual. OpenCode already has built-in `task` tool; this plugin's main value is persistence across compaction.
- **Alternative (archived)**: `opencode-background` (zenobi-us) — archived since Mar 14 2026

## Other Useful Plugins

### opencode-snip
- **Plugin repo**: https://github.com/VincentHardouin/opencode-snip
- **snip CLI repo**: https://github.com/edouard-claude/snip
- **What it does**: Auto-prefixes shell commands with `snip` CLI proxy that filters output before reaching LLM — 60-90% token reduction
- **Example**: `go test ./...` drops from 689 tokens to 16 (97.7% savings)
- **Install snip CLI**: `curl -fsSL https://raw.githubusercontent.com/edouard-claude/snip/master/install.sh | sh`
- **Install plugin**: `{ "plugin": ["opencode-snip@latest"] }`

### CC Safety Net (kenryu42)
- **Repo**: https://github.com/kenryu42/claude-code-safety-net
- **What it does**: Semantic command analysis that blocks destructive git/filesystem commands before they execute. Catches bypasses that manual allow/deny wildcards miss (flag reordering, shell wrappers, interpreter one-liners).
- **Vs manual allow/deny**: Manual rules are coarse wildcard matching with known bypass vectors. Safety Net does recursive analysis (5 levels of shell wrappers), interpreter detection, flag normalization. Defense-in-depth.
- **Activity**: 1,300 stars, 60 forks, 362 commits, 16 releases — very mature
- **Install**: `{ "plugin": ["cc-safety-net"] }`

### opencode-canvas
- **Repo**: https://github.com/mailshieldai/opencode-canvas
- **What it does**: Port of Claude Canvas — agent spawns interactive TUI widgets in tmux splits (calendar, document editor, flight booking). Requires tmux + Bun.
- **Verdict**: Cool tech demo, skip unless you have specific need for terminal TUIs

### open-plan-annotator
- **Repo**: https://github.com/ndom91/open-plan-annotator
- **What it does**: Intercepts plan mode, opens browser React UI to annotate plans (strikethrough/replace/insert/comment) before approving
- **Install**: `{ "plugin": ["open-plan-annotator@latest"] }`
