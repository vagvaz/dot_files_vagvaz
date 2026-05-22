# Global Agent Instructions

## Model
- Primary: qwen3.6 via Ollama (http://192.168.0.179:11234/v1)
- Secondary: qwen3-coder-next via Ollama

## Workflow
- **Plan-first**: Before any implementation, present a concise plan to the user and wait for explicit consent before proceeding.
- Use subagents for specialized tasks (explorer, oracle, librarian, designer, fixer, observer)
- Run tests and type checks after code changes
- Keep responses concise

## MCP Servers
- **serena**: Code intelligence at http://127.0.0.1:8765/sse
  - Serena's tools are auto-called via extension on startup (session_init with project)
  - Use `session_init`, `activate_project`, `find_symbol`, `read_memory` etc.
- **context7**: Up-to-date library documentation

## Security
- nono sandbox is available for running untrusted commands
- Do not expose API keys or secrets in code or memory
