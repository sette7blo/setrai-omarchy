#!/usr/bin/env bash
# Thin wrapper the QML panel shells out to, so it doesn't need to know the URL.
set -euo pipefail
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/setrai-omarchy/config"
SETRAI_URL="${SETRAI_URL:-http://localhost:3000}"
if [[ -f "$CONFIG_FILE" ]]; then . "$CONFIG_FILE"; fi
xdg-open "$SETRAI_URL${1:-/}" >/dev/null 2>&1 &
disown
