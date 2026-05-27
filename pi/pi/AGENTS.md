# Global Agent Instructions

## Model
- Primary: qwen3.6 via Ollama (http://192.168.0.179:11234/v1)
- Secondary: qwen3-coder-next via Ollama

## Workflow
- When you get a task understand if it is a coding t ask or not if not proceed to complete it, create a plan before jumping into actions
- for coding tasks **Plan-first**: Before any implementation, present a concise plan to the user and wait for explicit consent before proceeding and try to delegate to your very capable group of agents, analyze the type of task and delegate to your available specialized subagents:
- explorer: for code exploraton, code discovering tasks
- fixer: for generating for small/medium size code
- librarian: For reading documentation and understanding APIs
- designer: For designing rich UI experiences and mockus
- oracle: For very complex design and architecture tasks
- When you generate a subtask give enough information to the subagent to complete  the task but keep it concise
- try to delegate as much as possible
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
