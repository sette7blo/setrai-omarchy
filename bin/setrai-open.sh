#!/usr/bin/env bash
# Thin wrapper the QML panel shells out to, so it doesn't need to know the URL.
set -euo pipefail
exec "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/setrai" open "${1:-/}"
