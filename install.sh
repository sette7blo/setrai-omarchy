#!/usr/bin/env bash
# Idempotent installer for the setrai Omarchy plugin.
# Links the bar widget, CLI, launcher, menu entries and agent skills.

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="io.github.sette7blo.setrai"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
PLUGIN_LINK="$CONFIG_HOME/omarchy/plugins/$PLUGIN_ID"
CLI_LINK="$HOME/.local/bin/setrai"
DESKTOP_LINK="$HOME/.local/share/applications/setrai.desktop"
MENU_LINK="$CONFIG_HOME/omarchy/extensions/omarchy-menu-setrai.jsonc"
HOOK_LINK="$CONFIG_HOME/omarchy/hooks/post-boot.d/50-setrai.sh"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_FILE="$CONFIG_HOME/setrai-omarchy/config"
CONNECTION_DIR="$STATE_HOME/omarchy/setrai"
CONNECTION_FILE="$CONNECTION_DIR/credentials.json"

SETRAI_URL=""
AUTOSTART=false
COMPOSE_PATH=""

usage() {
  cat <<EOF
Usage: $0 [--setrai-url URL] [--autostart --compose /path/to/compose.yml]

--setrai-url sets the server address the plugin and the setrai CLI share.
It can be changed later in the plugin's Settings view.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --setrai-url)
      [[ $# -ge 2 ]] || { echo "Missing value for --setrai-url" >&2; exit 2; }
      SETRAI_URL="$2"; shift 2 ;;
    --autostart)
      AUTOSTART=true; shift ;;
    --compose)
      [[ $# -ge 2 ]] || { echo "Missing value for --compose" >&2; exit 2; }
      COMPOSE_PATH="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      usage; exit 2 ;;
  esac
done

if [[ -n "$SETRAI_URL" && ! "$SETRAI_URL" =~ ^https?://[^[:space:]\"\\]+$ ]]; then
  echo "--setrai-url must be an http:// or https:// address" >&2
  exit 2
fi

if $AUTOSTART && [[ -z "$COMPOSE_PATH" ]]; then
  echo "--autostart requires --compose /path/to/compose.yml" >&2
  exit 2
fi

log() { printf '[setrai] %s\n' "$*"; }

link_path() {
  local source_path="$1"
  local target_path="$2"
  mkdir -p "$(dirname "$target_path")"
  if [[ -L "$target_path" && "$(readlink -f "$target_path")" == "$(readlink -f "$source_path")" ]]; then
    return
  fi
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    mv "$target_path" "$target_path.bak.$TIMESTAMP"
    log "backed up existing $target_path"
  fi
  ln -s "$source_path" "$target_path"
}

write_config() {
  mkdir -p "$(dirname "$CONFIG_FILE")"
  cat > "$CONFIG_FILE" <<EOF
# Managed by $PLUGIN_ID install.sh
SETRAI_COMPOSE=${COMPOSE_PATH:-}
EOF
  log "wrote $CONFIG_FILE"
}

# The server address lives with the API key in the connection file, which the
# plugin's Settings view also writes. Only touch it when --setrai-url is given.
write_connection() {
  [[ -n "$SETRAI_URL" ]] || return 0
  local url="${SETRAI_URL%/}"
  mkdir -p "$CONNECTION_DIR"
  chmod 700 "$CONNECTION_DIR"
  if [[ -s "$CONNECTION_FILE" ]]; then
    if ! command -v jq >/dev/null 2>&1; then
      log "jq not found; set the server address in the plugin's Settings view"
      return
    fi
    local tmp
    tmp="$(mktemp -p "$CONNECTION_DIR" .tmp.XXXXXX)"
    jq --arg url "$url" '.baseUrl = $url' "$CONNECTION_FILE" > "$tmp"
    chmod 600 "$tmp"
    mv -f "$tmp" "$CONNECTION_FILE"
  else
    (umask 077; printf '{\n  "baseUrl": "%s",\n  "apiKey": ""\n}\n' "$url" > "$CONNECTION_FILE")
  fi
  log "set server address in $CONNECTION_FILE"
}

install_plugin_link() {
  link_path "$PROJECT_DIR" "$PLUGIN_LINK"
  log "linked plugin dir → $PLUGIN_LINK"
}

install_cli() {
  chmod +x "$PROJECT_DIR/bin/setrai"
  link_path "$PROJECT_DIR/bin/setrai" "$CLI_LINK"
  log "linked CLI → $CLI_LINK"
}

install_desktop() {
  # The launcher goes through the CLI so it follows the configured address.
  local tmp="$PROJECT_DIR/setrai.desktop"
  sed "s|@@SETRAI_CLI@@|$CLI_LINK|g" "$PROJECT_DIR/setrai.desktop.in" > "$tmp"
  link_path "$tmp" "$DESKTOP_LINK"
  log "linked .desktop → $DESKTOP_LINK"
}

install_menu() {
  link_path "$PROJECT_DIR/extensions/omarchy-menu.jsonc" "$MENU_LINK"
  log "linked menu extension → $MENU_LINK"
}

install_hook() {
  if $AUTOSTART; then
    chmod +x "$PROJECT_DIR/hooks/post-boot.sh"
    link_path "$PROJECT_DIR/hooks/post-boot.sh" "$HOOK_LINK"
    log "linked autostart hook → $HOOK_LINK"
  else
    [[ -L "$HOOK_LINK" ]] && { unlink "$HOOK_LINK"; log "removed stale autostart hook"; } || true
  fi
}

install_skills() {
  local skill_src skill_name
  for skill_src in "$PROJECT_DIR"/agent-skill/*/; do
    [[ -d "$skill_src" ]] || continue
    skill_name="$(basename "$skill_src")"
    for agent_home in "$HOME/.claude" "$HOME/.codex" "$HOME/.agents" "$HOME/.copilot"; do
      if [[ -d "$agent_home" ]]; then
        link_path "${skill_src%/}" "$agent_home/skills/$skill_name"
        log "linked skill $skill_name → $agent_home/skills/"
      fi
    done
  done
}

register_omarchy() {
  if ! command -v omarchy >/dev/null 2>&1; then
    log "omarchy not found on PATH — skipping validate/enable"
    return
  fi
  omarchy plugin validate "$PROJECT_DIR"
  if omarchy-shell shell rescanPlugins >/dev/null 2>&1; then
    omarchy plugin enable "$PLUGIN_ID" right >/dev/null 2>&1 || true
  fi
  # Quickshell may hold an older BarWidget component in memory after a rescan.
  omarchy restart shell >/dev/null 2>&1 || true
}

main() {
  log "plugin dir: $PROJECT_DIR"
  write_config
  write_connection
  install_plugin_link
  install_cli
  install_desktop
  install_menu
  install_hook
  install_skills
  register_omarchy
  log "done. Click the Setrai icon on the bar and open Settings to connect."
}

main "$@"
