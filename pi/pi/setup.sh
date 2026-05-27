#!/usr/bin/env bash
# =============================================================================
# Pi Coding Agent — Reproducible Setup Script
# =============================================================================
# Installs Pi, all extensions, configures models/MCP/profiles/skills/agents,
# provider denylist, and custom extensions.
# Designed to be idempotent — safe to run multiple times.
#
# Usage:
#   ./setup.sh              # Full setup with all extensions
#   ./setup.sh --no-skills  # Skip copying skills (faster)
#   ./setup.sh --dry-run    # Print commands without executing
# =============================================================================

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

PI_AGENT_DIR="${PI_AGENT_DIR:-$HOME/.pi/agent}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# Ollama provider settings
OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://192.168.0.179:11234/v1}"

# MCP servers
SERENA_URL="${SERENA_URL:-http://127.0.0.1:8765/sse}"

# Default profile
DEFAULT_PROFILE="${DEFAULT_PROFILE:-online}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
NO_SKILLS=false

# ─── Helpers ─────────────────────────────────────────────────────────────────

log()    { echo -e "${BLUE}[pi-setup]${NC} $*"; }
ok()     { echo -e "${GREEN}[✓]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
err()    { echo -e "${RED}[✗]${NC} $*" >&2; }

run() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

require_cmd() {
  if ! command -v "$1" &>/dev/null; then
    err "$1 is required but not installed."
    return 1
  fi
}

# ─── Argument parsing ────────────────────────────────────────────────────────

for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --no-skills) NO_SKILLS=true ;;
    --help|-h)
      echo "Usage: $0 [--dry-run] [--no-skills]"
      echo "  --dry-run    Print commands without executing"
      echo "  --no-skills  Skip copying skills (faster)"
      exit 0
      ;;
    *) err "Unknown argument: $arg"; exit 1 ;;
  esac
done

# ─── Prerequisites ───────────────────────────────────────────────────────────

log "Checking prerequisites..."

require_cmd npm || { err "Install Node.js first"; exit 1; }
require_cmd node || { err "Install Node.js first"; exit 1; }

NODE_VERSION=$(node -v | cut -d. -f1 | tr -d 'v')
if [ "$NODE_VERSION" -lt 18 ]; then
  err "Node.js 18+ required (found $(node -v))"
  exit 1
fi

ok "Node.js $(node -v)"

# ─── Step 1: Install Pi ─────────────────────────────────────────────────────

log "Step 1: Installing Pi coding agent..."

if command -v pi &>/dev/null; then
  PI_VERSION=$(pi --version 2>/dev/null || echo "unknown")
  ok "Pi already installed ($PI_VERSION)"
else
  log "Installing Pi..."
  run npm install -g @earendil-works/pi-coding-agent
  ok "Pi installed"
fi

# ─── Step 2: Create directory structure ──────────────────────────────────────

log "Step 2: Creating directory structure..."

for dir in agents extensions profiles skills themes; do
  run mkdir -p "$PI_AGENT_DIR/$dir"
done

ok "Directories created"

# ─── Step 3: Install npm extensions ─────────────────────────────────────────

log "Step 3: Installing Pi extensions..."

EXTENSIONS=(
  "pi-mcp-adapter"
  "pi-subagents"
  "pi-hermes-memory"
  "@juanibiapina/pi-powerbar"
  "@tmustier/pi-usage-extension"
  "pi-dcp"
  "@dreki-gg/pi-plan-mode"
)

for ext in "${EXTENSIONS[@]}"; do
  if [ -d "$PI_AGENT_DIR/npm/node_modules/$ext" ] || \
     [ -d "$PI_AGENT_DIR/npm/node_modules/${ext#@*/}" ]; then
    ok "$ext (already installed)"
  else
    log "Installing $ext..."
    if run pi install "npm:$ext" 2>/dev/null; then
      ok "$ext installed"
    else
      warn "Failed to install $ext via pi install, trying npm directly..."
      if run npm install "$ext" --prefix "$PI_AGENT_DIR/npm" --ignore-scripts 2>/dev/null; then
        ok "$ext installed (npm fallback)"
      else
        err "Failed to install $ext"
      fi
    fi
  fi
done

# ─── Step 4: Install nono (kernel sandbox) ──────────────────────────────────

log "Step 4: Checking nono..."

if command -v nono &>/dev/null; then
  ok "nono already installed ($(nono --version))"
else
  if command -v cargo &>/dev/null; then
    log "Installing nono via cargo..."
    run cargo install nono-cli
    ok "nono installed"
  else
    warn "nono not installed and cargo not available. Install manually:"
    warn "  cargo install nono-cli"
  fi
fi

# ─── Step 5: Deploy config files ────────────────────────────────────────────

log "Step 5: Deploying configuration files..."

deploy_if_missing() {
  local src="$1"
  local dest="$2"
  local label="$3"
  if [ -f "$dest" ]; then
    ok "  $label (already exists, skipping)"
  else
    if $DRY_RUN; then
      echo "  [dry-run] cp $src → $dest"
    else
      cp "$src" "$dest"
    fi
    ok "  $label"
  fi
}

deploy_force() {
  local src="$1"
  local dest="$2"
  local label="$3"
  if $DRY_RUN; then
    echo "  [dry-run] cp $src → $dest"
  else
    cp "$src" "$dest"
  fi
  ok "  $label (deployed)"
}

# models.json — force deploy (source of truth for model config)
deploy_force "$DOTFILES_DIR/models.json" "$PI_AGENT_DIR/models.json" "models.json"

# mcp.json — only create if missing
deploy_if_missing "$DOTFILES_DIR/mcp.json" "$PI_AGENT_DIR/mcp.json" "mcp.json"

# AGENTS.md — NEVER overwrite user's customizations, only create if missing
deploy_if_missing "$DOTFILES_DIR/AGENTS.md" "$PI_AGENT_DIR/AGENTS.md" "AGENTS.md"

# deny_providers.json — NEVER overwrite, only create if missing
deploy_if_missing "$DOTFILES_DIR/deny_providers.json" "$PI_AGENT_DIR/deny_providers.json" "deny_providers.json"

# profiles
for profile in local online; do
  if [ -f "$DOTFILES_DIR/profiles/$profile.json" ]; then
    deploy_if_missing "$DOTFILES_DIR/profiles/$profile.json" "$PI_AGENT_DIR/profiles/$profile.json" "profiles/$profile.json"
  fi
done

if [ -f "$DOTFILES_DIR/profiles/profiles.json" ]; then
  deploy_if_missing "$DOTFILES_DIR/profiles/profiles.json" "$PI_AGENT_DIR/profiles/profiles.json" "profiles/profiles.json"
fi

# Theme
if [ -f "$DOTFILES_DIR/themes/tokyonight.json" ]; then
  deploy_if_missing "$DOTFILES_DIR/themes/tokyonight.json" "$PI_AGENT_DIR/themes/tokyonight.json" "themes/tokyonight.json"
fi

# ─── Step 6: Deploy agents ──────────────────────────────────────────────────

log "Step 6: Deploying agent definitions..."

if [ -d "$DOTFILES_DIR/agents" ]; then
  for agent_file in "$DOTFILES_DIR/agents/"*.md; do
    dest="$PI_AGENT_DIR/agents/$(basename "$agent_file")"
    deploy_if_missing "$agent_file" "$dest" "agents/$(basename "$agent_file")"
  done
fi

# ─── Step 7: Deploy custom extensions ──────────────────────────────────────

log "Step 7: Deploying custom extensions..."

# powerbar-extra.ts
if [ -f "$DOTFILES_DIR/extensions/powerbar-extra.ts" ]; then
  deploy_if_missing "$DOTFILES_DIR/extensions/powerbar-extra.ts" "$PI_AGENT_DIR/extensions/powerbar-extra.ts" "extensions/powerbar-extra.ts"
fi

# profile-switcher.ts
if [ -f "$DOTFILES_DIR/extensions/profile-switcher.ts" ]; then
  deploy_if_missing "$DOTFILES_DIR/extensions/profile-switcher.ts" "$PI_AGENT_DIR/extensions/profile-switcher.ts" "extensions/profile-switcher.ts"
fi

# serena-init.ts
if [ -f "$DOTFILES_DIR/extensions/serena-init.ts" ]; then
  deploy_if_missing "$DOTFILES_DIR/extensions/serena-init.ts" "$PI_AGENT_DIR/extensions/serena-init.ts" "extensions/serena-init.ts"
fi

# web-tools (with its own package.json)
if [ -f "$DOTFILES_DIR/extensions/web-tools/index.ts" ]; then
  run mkdir -p "$PI_AGENT_DIR/extensions/web-tools"

  deploy_if_missing "$DOTFILES_DIR/extensions/web-tools/index.ts" "$PI_AGENT_DIR/extensions/web-tools/index.ts" "extensions/web-tools/index.ts"
  deploy_if_missing "$DOTFILES_DIR/extensions/web-tools/package.json" "$PI_AGENT_DIR/extensions/web-tools/package.json" "extensions/web-tools/package.json"

  # Install dependencies for web-tools
  if [ -d "$PI_AGENT_DIR/extensions/web-tools/node_modules" ]; then
    ok "  extensions/web-tools (deps already installed)"
  else
    log "  Installing web-tools dependencies..."
    if $DRY_RUN; then
      echo "  [dry-run] npm install --prefix $PI_AGENT_DIR/extensions/web-tools"
    else
      npm install --prefix "$PI_AGENT_DIR/extensions/web-tools" 2>/dev/null
    fi
    ok "  extensions/web-tools"
  fi
fi

# provider_denylist (no npm deps needed)
if [ -d "$DOTFILES_DIR/extensions/provider_denylist" ]; then
  if [ -d "$PI_AGENT_DIR/extensions/provider_denylist" ]; then
    ok "  extensions/provider_denylist (already exists, skipping)"
  else
    run mkdir -p "$PI_AGENT_DIR/extensions/provider_denylist"
    if $DRY_RUN; then
      echo "  [dry-run] cp $DOTFILES_DIR/extensions/provider_denylist/index.ts → $PI_AGENT_DIR/extensions/provider_denylist/index.ts"
    else
      cp "$DOTFILES_DIR/extensions/provider_denylist/index.ts" "$PI_AGENT_DIR/extensions/provider_denylist/index.ts"
    fi
    ok "  extensions/provider_denylist"
  fi
fi

# ─── Step 8: Deploy skills ──────────────────────────────────────────────────

if ! $NO_SKILLS; then
  log "Step 8: Deploying skills..."

  if [ -d "$DOTFILES_DIR/skills" ]; then
    for skill_dir in "$DOTFILES_DIR/skills"/*/; do
      skill_name=$(basename "$skill_dir")
      dest="$PI_AGENT_DIR/skills/$skill_name"
      if [ -d "$dest" ]; then
        ok "  skills/$skill_name (already exists, skipping)"
      else
        if $DRY_RUN; then
          echo "  [dry-run] cp -r $skill_dir → $dest"
        else
          cp -r "$skill_dir" "$dest"
        fi
        ok "  skills/$skill_name"
      fi
    done
  fi
else
  log "Step 8: Skipping skills (--no-skills)"
fi

# ─── Step 9: Set default profile ────────────────────────────────────────────

log "Step 9: Setting default profile to '$DEFAULT_PROFILE'..."

if [ -f "$PI_AGENT_DIR/settings.json" ]; then
  # Update activeProfile in existing settings.json
  if command -v python3 &>/dev/null; then
    if $DRY_RUN; then
      echo "  [dry-run] python3 -c \"set activeProfile to '$DEFAULT_PROFILE'\""
    else
      python3 -c "
import json
with open('$PI_AGENT_DIR/settings.json') as f:
    settings = json.load(f)
settings['activeProfile'] = '$DEFAULT_PROFILE'
with open('$PI_AGENT_DIR/settings.json', 'w') as f:
    json.dump(settings, f, indent=2)
"
    fi
    ok "  activeProfile set to '$DEFAULT_PROFILE'"
  else
    warn "python3 not found, skipping profile activation"
  fi
else
  # Copy template from dotfiles
  if [ -f "$DOTFILES_DIR/settings.json" ]; then
    deploy_if_missing "$DOTFILES_DIR/settings.json" "$PI_AGENT_DIR/settings.json" "settings.json"
  fi
  # Set activeProfile
  if [ -f "$PI_AGENT_DIR/settings.json" ] && command -v python3 &>/dev/null; then
    if $DRY_RUN; then
      echo "  [dry-run] python3 -c \"set activeProfile to '$DEFAULT_PROFILE'\""
    else
      python3 -c "
import json
with open('$PI_AGENT_DIR/settings.json') as f:
    settings = json.load(f)
settings['activeProfile'] = '$DEFAULT_PROFILE'
with open('$PI_AGENT_DIR/settings.json', 'w') as f:
    json.dump(settings, f, indent=2)
"
    fi
    ok "  activeProfile set to '$DEFAULT_PROFILE'"
  fi
fi

# ─── Done ────────────────────────────────────────────────────────────────────

echo ""
log "=========================================="
log "  Pi Coding Agent setup complete!"
log "=========================================="
echo ""
log "Next steps:"
echo "  1. Start Pi:  pi"
echo "  2. Switch profiles:  /profile local  or  /profile online"
echo "  3. List profiles:    /profile list"
echo "  4. Reload after config changes:  /reload"
echo ""
log "Installed npm packages:"
echo "  - pi-mcp-adapter       (Serena + Context7 MCP)"
echo "  - pi-subagents         (multi-agent delegation)"
echo "  - pi-hermes-memory     (persistent memory)"
echo "  - pi-powerbar          (status bar)"
echo "  - pi-usage-extension   (token/cost tracking)"
echo "  - pi-dcp               (dynamic context pruning)"
echo "  - pi-plan-mode         (read-only planning)"
echo ""
log "Custom extensions:"
echo "  - web-tools            (DuckDuckGo search + URL fetch)"
echo "  - profile-switcher     (/profile command)"
echo "  - serena-init          (auto-init Serena via SSE)"
echo "  - provider_denylist    (blocks unused built-in providers)"
echo ""
log "Denied providers (configurable in deny_providers.json):"
echo "  $(cat "$DOTFILES_DIR/deny_providers.json" 2>/dev/null | python3 -c "import sys,json; print(', '.join(json.load(sys.stdin)))" 2>/dev/null || echo 'all built-in providers except opencode-go')"
echo ""
log "Agents: explorer, oracle, librarian, designer, fixer, observer"
log "Skills: $(ls -d "$PI_AGENT_DIR/skills"/*/ 2>/dev/null | wc -l) skills deployed"
echo ""
