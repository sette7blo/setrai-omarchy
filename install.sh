#!/usr/bin/env bash
# Idempotent installer for the setrai Omarchy plugin.
# Links the bar widget, CLI and launcher. The agent skills are linked only on
# request, with --skills: the coach is handed them by path and needs no links.

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PLUGIN_ID="io.github.sette7blo.setrai"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
PLUGIN_LINK="$CONFIG_HOME/omarchy/plugins/$PLUGIN_ID"
CLI_LINK="$HOME/.local/bin/setrai"
DESKTOP_LINK="$HOME/.local/share/applications/setrai.desktop"
MENU_FILE="$CONFIG_HOME/omarchy/extensions/omarchy-menu.jsonc"
MENU_OLD_LINK="$CONFIG_HOME/omarchy/extensions/omarchy-menu-setrai.jsonc"
MENU_BEGIN="// >>> setrai"
MENU_END="// <<< setrai"
HOOK_LINK="$CONFIG_HOME/omarchy/hooks/post-boot.d/50-setrai.sh"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_FILE="$CONFIG_HOME/setrai-omarchy/config"
CONNECTION_DIR="$STATE_HOME/omarchy/setrai"
CONNECTION_FILE="$CONNECTION_DIR/credentials.json"

SETRAI_URL=""
AUTOSTART=false
COMPOSE_PATH=""
SKILLS=false

usage() {
  cat <<EOF
Usage: $0 [--setrai-url URL] [--autostart --compose /path/to/compose.yml] [--skills]

--setrai-url sets the server address the plugin and the setrai CLI share.
It can be changed later in the plugin's Settings view.
--skills also links the agent skills into the agent homes that exist
(~/.claude, ~/.codex, ~/.agents, ~/.copilot). Without it, no skill links are
made or changed. uninstall.sh removes them.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --setrai-url)
      [[ $# -ge 2 ]] || { echo "Missing value for --setrai-url" >&2; exit 2; }
      SETRAI_URL="$2"; shift 2 ;;
    --autostart)
      AUTOSTART=true; shift ;;
    --skills)
      SKILLS=true; shift ;;
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

# Never replaces or moves anything: when the path is already taken by something
# that is not this plugin's link, it is left as it is. The plugin calls its own
# bin/ directly, so it works without the link.
link_path() {
  local source_path="$1"
  local target_path="$2"
  mkdir -p "$(dirname "$target_path")"
  if [[ -L "$target_path" && "$(readlink -f "$target_path")" == "$(readlink -f "$source_path")" ]]; then
    return 0
  fi
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    log "left $target_path as it is: something else is already there"
    return 0
  fi
  ln -s "$source_path" "$target_path"
  log "linked $target_path"
}

# A link that points into this plugin, as opposed to one the user made.
ours() {
  local target
  [[ -L "$1" ]] || return 1
  target="$(readlink -m "$1")"
  [[ "$target" == "$PROJECT_DIR" || "$target" == "$PROJECT_DIR/"* ]]
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
}

install_cli() {
  chmod +x "$PROJECT_DIR/bin/setrai"
  link_path "$PROJECT_DIR/bin/setrai" "$CLI_LINK"
}

# The launcher runs the plugin's own bin/setrai, never ~/.local/bin/setrai:
# that path may belong to another program the installer left alone. A plugin
# path that would need quoting in an Exec key gets no launcher at all.
desktop_path_ok() {
  [[ "$PROJECT_DIR" =~ ^[A-Za-z0-9._/+-]+$ ]]
}

render_desktop() {
  sed "s|@@SETRAI_CLI@@|$PROJECT_DIR/bin/setrai|g" "$PROJECT_DIR/setrai.desktop.in"
}

install_desktop() {
  # The launcher goes through the CLI so it follows the configured address.
  local tmp="$PROJECT_DIR/setrai.desktop"
  if ! desktop_path_ok; then
    log "no launcher: the plugin path has characters a launcher cannot hold safely"
    return 0
  fi
  render_desktop > "$tmp"
  link_path "$tmp" "$DESKTOP_LINK"
}

# Earlier versions added a Fitness section to the Omarchy menu. The plugin no
# longer touches the menu, so take out what they left behind.
remove_old_menu() {
  if ours "$MENU_OLD_LINK"; then
    unlink "$MENU_OLD_LINK"
    log "removed old menu link $MENU_OLD_LINK"
  fi
  [[ -f "$MENU_FILE" ]] && grep -qF -- "$MENU_BEGIN" "$MENU_FILE" || return 0
  local tmp
  tmp="$(mktemp -p "$(dirname "$MENU_FILE")" .omarchy-menu.XXXXXX)"
  awk -v begin="$MENU_BEGIN" -v end="$MENU_END" '
    index($0, begin) { skipping = 1; next }
    skipping { if (index($0, end)) skipping = 0; next }
    { print }
  ' "$MENU_FILE" > "$tmp"
  chmod 644 "$tmp"
  mv -f "$tmp" "$MENU_FILE"
  log "removed the Fitness section from $MENU_FILE"
  if command -v omarchy-menu >/dev/null 2>&1; then
    omarchy-menu refresh >/dev/null 2>&1 || true
  fi
}

install_hook() {
  if $AUTOSTART; then
    chmod +x "$PROJECT_DIR/hooks/post-boot.sh"
    link_path "$PROJECT_DIR/hooks/post-boot.sh" "$HOOK_LINK"
  else
    ours "$HOOK_LINK" && { unlink "$HOOK_LINK"; log "removed stale autostart hook"; } || true
  fi
}

install_skills() {
  $SKILLS || return 0
  local skill_src skill_name
  for skill_src in "$PROJECT_DIR"/agent-skill/*/; do
    [[ -d "$skill_src" ]] || continue
    skill_name="$(basename "$skill_src")"
    for agent_home in "$HOME/.claude" "$HOME/.codex" "$HOME/.agents" "$HOME/.copilot"; do
      if [[ -d "$agent_home" ]]; then
        link_path "${skill_src%/}" "$agent_home/skills/$skill_name"
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
  remove_old_menu
  install_hook
  install_skills
  register_omarchy
  log "done. Click the Setrai icon on the bar and open Settings to connect."
}

main "$@"
