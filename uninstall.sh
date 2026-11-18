#!/usr/bin/env bash
# Reverses install.sh — removes symlinks, local config, cached credentials
# and the API-key header cache. Never touches the Setrai server itself.

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PLUGIN_ID="io.github.sette7blo.setrai"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
PLUGIN_LINK="$CONFIG_HOME/omarchy/plugins/$PLUGIN_ID"
CLI_LINK="$HOME/.local/bin/setrai"
DESKTOP_LINK="$HOME/.local/share/applications/setrai.desktop"
MENU_FILE="$CONFIG_HOME/omarchy/extensions/omarchy-menu.jsonc"
MENU_OLD_LINK="$CONFIG_HOME/omarchy/extensions/omarchy-menu-setrai.jsonc"
MENU_BEGIN="// >>> setrai"
MENU_END="// <<< setrai"
HOOK_LINK="$CONFIG_HOME/omarchy/hooks/post-boot.d/50-setrai.sh"
CONFIG_DIR="$CONFIG_HOME/setrai-omarchy"
STATE_DIR="$STATE_HOME/omarchy/setrai"
CACHE_DIR="$CACHE_HOME/omarchy/setrai"

log() { printf '[setrai] %s\n' "$*"; }

# Removes only links that point into this plugin; a command or launcher of the
# same name from somewhere else stays.
remove_link() {
  local path="$1" target
  [[ -L "$path" ]] || return 0
  target="$(readlink -m "$path")"
  [[ "$target" == "$PROJECT_DIR" || "$target" == "$PROJECT_DIR/"* ]] || return 0
  unlink "$path"
  log "removed $path"
}

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable "$PLUGIN_ID" >/dev/null 2>&1 || true
  omarchy plugin remove "$PLUGIN_ID" >/dev/null 2>&1 || true
fi

remove_link "$PLUGIN_LINK"
remove_link "$CLI_LINK"
remove_link "$DESKTOP_LINK"
remove_link "$MENU_OLD_LINK"
remove_link "$HOOK_LINK"

# The Fitness section that versions before 0.4.0 merged into the user's menu file.
if [[ -f "$MENU_FILE" ]] && grep -qF -- "$MENU_BEGIN" "$MENU_FILE"; then
  tmp="$(mktemp -p "$(dirname "$MENU_FILE")" .omarchy-menu.XXXXXX)"
  awk -v begin="$MENU_BEGIN" -v end="$MENU_END" '
    index($0, begin) { skipping = 1; next }
    skipping { if (index($0, end)) skipping = 0; next }
    { print }
  ' "$MENU_FILE" > "$tmp"
  chmod 644 "$tmp"
  mv -f "$tmp" "$MENU_FILE"
  log "removed Fitness entries from $MENU_FILE"
fi

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
