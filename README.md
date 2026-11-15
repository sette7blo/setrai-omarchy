# setrai-omarchy

Omarchy plugin for [Setrai](https://github.com/sette7blo/setrai): a bar icon
with a popover showing readiness, this week's training and body weight, a
one-tap resume for an open workout, Omarchy menu entries, a launcher
`.desktop`, and agent skills so Claude Code, Codex or Copilot can start
workouts and log body weight from natural language.

Setrai runs on its own (PWA on iOS, Docker on a server). The plugin talks to
its regular REST API with a Setrai API key you paste into the plugin's
Settings view. It does not calculate anything: every figure comes from the
Setrai API as the server returns it. The one thing it writes is today's body
weight, which you can log from the popover.

## Requirements

- Omarchy **Quattro** (v4.5+) with the plugin runtime
- Setrai v0.8.0 or newer (API keys, `readiness` and `bodyWeightChangeKg`).
  Create a key under
  **Settings > API keys** in the Setrai web UI. The key looks like
  `setrai_<43 chars>` and only the plaintext value is shown once.

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

After install, click the bar icon, then the gear icon. Enter the server
address and API key, click **Test connection**, then **Save**. Both are
written to `~/.local/state/omarchy/setrai/credentials.json` (mode 600), the
one place the plugin, the CLI, the menu, the launcher and the agent skills
read them from. `--setrai-url` only pre-fills the address there.

## What gets installed

| Location | What |
|---|---|
| `~/.config/omarchy/plugins/io.github.sette7blo.setrai` | Plugin dir (symlink to this repo) |
| `~/.local/bin/setrai` | CLI wrapper (symlink) |
| `~/.local/share/applications/setrai.desktop` | Launcher entry |
| `~/.config/omarchy/extensions/omarchy-menu-setrai.jsonc` | Menu extension |
| `~/.config/omarchy/hooks/post-boot.d/50-setrai.sh` | Autostart (optional, with `--autostart`) |
| `~/.config/setrai-omarchy/config` | Compose path for the optional autostart hook |
| `~/.local/state/omarchy/setrai/credentials.json` | Server address and API key (mode 600, written by the Settings view) |
| `~/.claude/skills/setrai-*`, `~/.codex/skills/setrai-*`, etc. | Agent skills (only if the agent dir exists) |

## Bar icon

- A dumbbell icon. It takes the accent colour while a workout is open and
  is dimmed until the plugin is connected.
- The tooltip shows the readiness, or the open workout's program.
- **Left-click** opens the popover. **Right-click** opens this README.

## Popover

From top to bottom:

- **Header**: `Workout in progress` and the program name while a session is
  open. The gear switches to the settings form.
- **Readiness**: the overall figure from `GET /api/recovery`, and when you
  last trained.
- **This week**: sessions (`trainingFrequency.thisWeek`) and volume
  (`weeklyVolume`) from `GET /api/statistics`.
- **Body weight**: latest entry, the total change (`bodyWeightChangeKg`)
  and a trend line over the full history. Type today's weight in the field
  and press Enter to log it (`POST /api/body-weight`); logging again the same
  day replaces the entry. Escape clears the field.
- **Open Setrai**, or **Resume workout** when a session is open.

The plugin polls `GET /api/sessions`, `GET /api/recovery` and
`GET /api/statistics` and `GET /api/profile` every 30 seconds by default (configurable), and when
the popover opens. If the server is unreachable or the key is rejected, the
popover says so and offers a button to open settings.

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
setrai body 72.4         # log today's weight in your profile's unit (asks if omitted)
setrai body 160lb        # a trailing kg or lb overrides the unit
setrai stats             # open statistics
setrai recovery          # open recovery
```

The CLI reads the server address and API key from
`~/.local/state/omarchy/setrai/credentials.json`. `SETRAI_URL` and
`SETRAI_API_KEY` in the environment override them for one-off runs.

## Agent skills

Install adds `SKILL.md` symlinks to whichever agent homes exist
(`~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`,
`~/.copilot/skills/`). Skills:

- **setrai-start-workout** — start a session from a saved program
- **setrai-quick-workout** — generate and start a constrained workout
- **setrai-log-body** — record body-weight
- **setrai-show-stats** — summarize volume, streak, records and body weight
- **setrai-recovery** — show readiness and per-muscle recovery

The skills read the same connection file, so they use whatever address and
key you saved in the plugin's Settings view.

## Theme

The icon and popover use the active Omarchy theme's foreground, accent and
font, and the shell's own panel components, so they follow theme and font
switches automatically.

## Uninstall

```sh
./uninstall.sh
```

Removes all symlinks, menu entries, the config dir, the connection file
and the header-cache dir, plus the plugin registration with Omarchy.
Does **not** touch the Setrai server or any API keys you've created
server-side — revoke those under **Settings > API keys** in the Setrai
web UI if you want them gone.

## Repository layout

```
manifest.json              Plugin manifest (kinds:[service, bar-widget])
Service.qml                Background poller + connection store
BarWidget.qml              The bar icon
Panel.qml                  The click-to-open popover
ReadinessView.qml          Overall readiness figure
BodyChart.qml              Latest body weight, total change, trend line, entry field
SettingsView.qml           Server address, API key and refresh form
Model.js                   Pure-JS helpers (parsing and formatting only)
bin/setrai                 CLI wrapper used by the menu + desktop entry
bin/setrai-open.sh         URL opener the Panel shells out to (calls bin/setrai)
setrai.desktop.in          Launcher template (install.sh fills in the CLI path)
extensions/omarchy-menu.jsonc   Menu fragment
hooks/post-boot.sh         Optional Docker-stack autostart
agent-skill/               Five SKILL.md files for AI coaches
install.sh / uninstall.sh  Idempotent install, clean uninstall
```

## License

MIT — see `LICENSE`.
