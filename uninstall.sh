#!/usr/bin/env bash
# Reverses install.sh — removes symlinks, local config, cached credentials
# and the API-key header cache. Never touches the Setrai server itself.

set -euo pipefail

PLUGIN_ID="io.github.sette7blo.setrai"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
PLUGIN_LINK="$CONFIG_HOME/omarchy/plugins/$PLUGIN_ID"
CLI_LINK="$HOME/.local/bin/setrai"
DESKTOP_LINK="$HOME/.local/share/applications/setrai.desktop"
MENU_LINK="$CONFIG_HOME/omarchy/extensions/omarchy-menu-setrai.jsonc"
HOOK_LINK="$CONFIG_HOME/omarchy/hooks/post-boot.d/50-setrai.sh"
CONFIG_DIR="$CONFIG_HOME/setrai-omarchy"
STATE_DIR="$STATE_HOME/omarchy/setrai"
CACHE_DIR="$CACHE_HOME/omarchy/setrai"

log() { printf '[setrai] %s\n' "$*"; }

remove_link() {
  local path="$1"
  if [[ -L "$path" ]]; then
    unlink "$path"
    log "removed $path"
  fi
}

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable "$PLUGIN_ID" >/dev/null 2>&1 || true
  omarchy plugin remove "$PLUGIN_ID" >/dev/null 2>&1 || true
fi

remove_link "$PLUGIN_LINK"
remove_link "$CLI_LINK"
remove_link "$DESKTOP_LINK"
remove_link "$MENU_LINK"
remove_link "$HOOK_LINK"

# Agent skill symlinks.
for agent_home in "$HOME/.claude" "$HOME/.codex" "$HOME/.agents" "$HOME/.copilot"; do
  [[ -d "$agent_home/skills" ]] || continue
  for skill in setrai-start-workout setrai-log-body setrai-show-stats setrai-quick-workout setrai-recovery setrai-create-program setrai-weekly-review; do
    remove_link "$agent_home/skills/$skill"
  done
done

for dir in "$CONFIG_DIR" "$STATE_DIR" "$CACHE_DIR"; do
  if [[ -d "$dir" ]]; then
    rm -rf "$dir"
    log "removed $dir"
  fi
done

if command -v omarchy >/dev/null 2>&1; then
  omarchy restart shell >/dev/null 2>&1 || true
fi

log "uninstalled $PLUGIN_ID"
