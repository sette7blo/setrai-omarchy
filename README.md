# setrai-omarchy

Omarchy plugin for [Setrai](https://github.com/sette7blo/setrai) — a bar pill
that glances at today's training volume (or resumes an open session), a
popover with weekly stats and recovery readiness, Omarchy menu entries, a
launcher `.desktop`, and agent skills so Claude Code / Codex / Copilot can
start workouts and log body weight by natural language.

Setrai runs independently (PWA on iOS, local Docker on this host); the
plugin reads a snapshot file Setrai writes. No server migration, no iOS
regression.

## Requirements

- Omarchy **Quattro** (v4.5+) with the plugin runtime
- Setrai with the Omarchy snapshot writer enabled:
  ```
  SETRAI_OMARCHY_SNAPSHOT_ENABLED=true
  # optional: SETRAI_OMARCHY_SNAPSHOT_PATH=/custom/path/snapshot.json
  ```
  Default snapshot path: `$XDG_DATA_HOME/setrai/snapshot.json`.

## Install

```sh
git clone https://github.com/sette7blo/setrai-omarchy
cd setrai-omarchy
./install.sh --setrai-url http://localhost:3000
```

Optional: auto-start the Setrai Docker stack at login (Omarchy post-boot
hook):

```sh
./install.sh --setrai-url http://localhost:3000 \
             --autostart --compose /path/to/setrai/compose.yml
```

The installer is idempotent — re-running it refreshes symlinks without
destructive side effects (existing non-symlink files are backed up with a
timestamp suffix).

## What gets installed

| Location | What |
|---|---|
| `~/.config/omarchy/plugins/io.github.sette7blo.setrai` | Plugin dir (symlink to this repo) |
| `~/.local/bin/setrai` | CLI wrapper (symlink) |
| `~/.local/share/applications/setrai.desktop` | Launcher entry |
| `~/.config/omarchy/extensions/omarchy-menu-setrai.jsonc` | Menu extension |
| `~/.config/omarchy/hooks/post-boot.d/50-setrai.sh` | Autostart (optional, with `--autostart`) |
| `~/.config/setrai-omarchy/config` | URL + compose path |
| `~/.claude/skills/setrai-*`, `~/.codex/skills/setrai-*`, etc. | Agent skills (only if the agent dir exists) |

## Bar pill

- Shows `⚡ <today's volume>` or `▶ Resume` if a session is open.
- **Left-click** → popover with: week volume, sessions, readiness bar, last
  workout, body weight.
- **Right-click** → opens this README.
- If the snapshot file is missing or Setrai isn't running, the panel shows
  an idle message and keeps rendering (no crash).

## Omarchy menu

A `Fitness` submenu:

| Entry | Action |
|---|---|
| Open Setrai | `setrai open` |
| Quick workout | `setrai quick` |
| Log body weight | `setrai body` |
| Show stats | `setrai stats` |

## CLI

```sh
setrai open              # open the PWA
setrai open /statistics  # open a specific page
setrai quick             # generate + start a quick workout
setrai body 72.4         # log 72.4 kg today (prompts if omitted)
setrai stats             # open statistics
setrai recovery          # open recovery
```

Config: `~/.config/setrai-omarchy/config` sets `SETRAI_URL` and
`SETRAI_COMPOSE`.

## Agent skills (Phase 4)

Install adds `SKILL.md` symlinks to whichever agent homes exist
(`~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`,
`~/.copilot/skills/`). Skills:

- **setrai-start-workout** — start a session from a saved program
- **setrai-quick-workout** — generate and start a constrained workout
- **setrai-log-body** — record body-weight
- **setrai-show-stats** — summarize volume / streak / PRs / body trend
- **setrai-recovery** — show per-muscle readiness

Skills assume `SETRAI_AUTH_ENABLED=false` and `localhost` — both fine on a
single-user box. If auth is turned on later, skills will need an API token
mechanism.

## Theme

The pill and popover read `bar.foreground` / `bar.background` /
`bar.accent` from the Omarchy Quattro runtime, so theme switches propagate
automatically. The semantic traffic-light for readiness
(green / amber / red) is intentionally theme-independent so meaning
survives an accent swap. `qml/ThemeColors.qml` additionally tails
`~/.local/state/omarchy/current/theme/colors.toml` for extra palette slots
(`fgDim`, `bgAlt`).

## Uninstall

```sh
./uninstall.sh
```

Removes all symlinks, menu entries, config dir and the plugin registration
with Omarchy. Does **not** touch Setrai server data or the snapshot file.

## Repository layout

```
manifest.json              Plugin manifest (schemaVersion:1, kinds:[bar-widget])
BarWidget.qml              The bar pill
Panel.qml                  The click-to-open popover
qml/ThemeColors.qml        Reactive palette reader + traffic-light constants
bin/setrai                 CLI wrapper used by the menu + desktop entry
bin/setrai-open.sh         Thin URL-opener the Panel shells out to
setrai.desktop.in          Launcher template (install.sh substitutes URL)
extensions/omarchy-menu.jsonc   Menu fragment
hooks/post-boot.sh         Optional Docker-stack autostart
agent-skill/               Five SKILL.md files for AI coaches
install.sh / uninstall.sh  Idempotent install, clean uninstall
```

## License

MIT — see `LICENSE`.
