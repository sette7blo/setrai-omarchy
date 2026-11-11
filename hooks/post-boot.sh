#!/usr/bin/env bash
# Optional: brings the Setrai Docker stack up at login.
# Installed to ~/.config/omarchy/hooks/post-boot.d/50-setrai.sh only when
# install.sh is run with --autostart --compose /path/to/compose.yml.

set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/setrai-omarchy/config"
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  . "$CONFIG_FILE"
fi

if [[ -z "${SETRAI_COMPOSE:-}" ]]; then
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  exit 0
fi

docker compose -f "$SETRAI_COMPOSE" up -d >/dev/null 2>&1 || true
