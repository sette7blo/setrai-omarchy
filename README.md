# setrai-omarchy

Omarchy plugin for [Setrai](https://github.com/sette7blo/setrai): a bar icon
with a popover showing readiness, this week's training and body weight, a
one-tap resume for an open workout, a `setrai` command, a launcher
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

The installer is idempotent. It never moves or replaces anything: a path that
already holds something else is left as it is. Add `--skills` to also link the
agent skills (see below).

After install, click the bar icon, then the gear icon. Enter the server
address and API key, click **Test connection**, then **Save**. Both are
written to `~/.local/state/omarchy/setrai/credentials.json` (mode 600), the
one place the plugin, the CLI, the launcher and the agent skills
read them from. `--setrai-url` only pre-fills the address there.

The key is sent only to that address. Every request disables curl's own
startup file (`~/.curlrc`) and refuses redirects, and the key goes to curl on
its standard input, never on a command line. Plain `http://` is accepted
as-is only for this machine (`localhost`, `127.x.x.x`, `[::1]`). For a plain
http address on another machine, Settings shows **Send the key over plain
http**: until you switch it on, nothing is sent there. The consent belongs to
that one address, so saving a different address drops it. Prefer https.

## What gets installed

| Location | What |
|---|---|
| `~/.config/omarchy/plugins/io.github.sette7blo.setrai` | Plugin dir (symlink to this repo) |
| `~/.local/bin/setrai` | CLI wrapper (symlink) |
| `~/.local/share/applications/setrai.desktop` | Launcher entry |
| `~/.config/omarchy/hooks/post-boot.d/50-setrai.sh` | Autostart (optional, with `--autostart`) |
| `~/.config/setrai-omarchy/config` | Compose path for the optional autostart hook |
| `~/.local/state/omarchy/setrai/credentials.json` | Server address and API key (mode 600, written by the Settings view) |
| `~/.claude/skills/setrai-*`, `~/.codex/skills/setrai-*`, etc. | Agent skills (only with `--skills`, and only if the agent dir exists) |

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
- **Start workout** lists your saved programs in the popover; click one to
  start the session and open it in its own window. While a session is open the button
  is **Resume workout** instead, and nothing new is started.
- **Open Setrai**.
- **Ask coach**, once the coach is switched on in Settings, docks Setrai on the
  left and opens your default Omarchy agent beside it as a training coach (see
  [Coach](#coach)).

The plugin polls `GET /api/sessions`, `GET /api/recovery` and
`GET /api/statistics` and `GET /api/profile` every 30 seconds by default (configurable), and when
the popover opens. If the server is unreachable or the key is rejected, the
popover says so and offers a button to open settings.

## CLI

```sh
setrai open              # open Setrai in its own window
setrai start             # pick a saved program and start it
setrai start 12          # start program 12 without asking
setrai open /statistics  # open a specific page
setrai quick             # generate + start a quick workout
setrai body 72.4         # log today's weight in your profile's unit (asks if omitted)
setrai body 160lb        # a trailing kg or lb overrides the unit
setrai coach             # open your default agent as a training coach
setrai stats             # open statistics
setrai recovery          # open recovery
```

The CLI reads the server address and API key from
`~/.local/state/omarchy/setrai/credentials.json` only, with the same rules as
the popover (no redirects, key on stdin, plain http only with consent).

## Agent skills

`./install.sh --skills` adds `SKILL.md` symlinks to whichever agent homes
exist (`~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`,
`~/.copilot/skills/`). Without `--skills` the installer makes no links there.
The coach does not need them: it is handed the skill files by path. Skills:

- **setrai-start-workout** — start a session from a saved program
- **setrai-quick-workout** — generate and start a constrained workout
- **setrai-log-body** — record body-weight
- **setrai-show-stats** — summarize volume, streak, records and body weight
- **setrai-recovery** — show readiness and per-muscle recovery
- **setrai-create-program** — design a program with you and save it
- **setrai-create-exercise** — add a missing exercise and give it a picture in
  the library's style (needs an agent that can generate images; the skill
  carries the style guide and four library pictures as references)
- **setrai-weekly-review** — read the week's sessions and suggest what to adjust

### Coach

The coach is off until you turn it on: open the popover's Settings and switch
on **Ask coach**. That adds the "Ask coach" button. Typing `setrai coach`
in a terminal works either way.

"Ask coach", or `setrai coach`, opens your default Omarchy agent
(`omarchy default agent <name>`) in a terminal with a prompt that points it at
these skills and starts with a weekly review. `setrai coach "<question>"`
starts from your question instead. The coach works with claude, codex,
cursor-agent and copilot. Omarchy's own launcher starts agents with their
permission prompts switched off; the coach starts the agent itself with its
normal prompts left in place, so it asks before it runs commands, and the
prompt tells it to ask before anything that writes to Setrai. If the coach
cannot open (no default agent, or one it does not support), Settings says why
and the button stays hidden; `setrai coach --check` prints the same reason.
Setrai has no AI of its own: your training data goes only to the agent you
chose.

The skills reach Setrai only through three commands in the plugin's `bin`
folder: `setrai-read /api/<path> [--jq '<filter>']` (GET),
`setrai-write <METHOD> /api/<path> '<json>'` (POST, PUT, PATCH, DELETE) and
`setrai-upload <exercise-id> <image-file>`, which attaches a JPEG, PNG, WebP or
GIF of up to 10 MB to an exercise (SVG is refused, since it can carry scripts).
They take only `/api/` paths, use the address and key saved in Settings (never an
environment override), and pass the key to curl on stdin, so the agent never
sees it. `--jq` picks fields from a large answer, so the coach does not need to
run python or jq itself, which would each ask for approval; the filter runs with
an empty environment and may not import files. Because every Setrai call is
one of these commands, the coach can pre-approve them. With the coach on, Settings has two more switches, both off
by default:

- **Read without asking**: `setrai-read` runs without a prompt.
- **Change without asking**: `setrai-write`, `setrai-upload` and `setrai start`/`open`
  run without a prompt, and the coach makes a change you asked for without
  asking you to confirm it. A program it designed is still shown before it is
  saved.

The approvals are passed for the coach's session only, with full paths, so
nothing else the agent wants to run is approved: claude gets `--allowedTools`,
copilot `--allow-tool`, and cursor-agent an allow list in
`~/.local/state/omarchy/setrai/coach/.cursor/cli.json`, the folder the coach
starts in. Your own agent settings are not touched. Codex has no per-command
approval, so with codex the coach still asks.

From the popover, the coach opens on the first empty workspace of the screen
you are on, with Setrai docked on its left edge and the terminal tiled into the
space to its right. Asking again while it is open takes you back to it. The dock shows
readiness, this week's sessions, volume and streak, the body weight chart,
recent sessions and saved programs, and refreshes every 15 seconds, so a
program the coach saves or a weight it logs appears there. It has no buttons
of its own: ask the coach, or use the popover. The dock is shown only on the
coach's workspace. The two close together: closing the terminal removes the
dock, and the dock's close button closes the terminal. `setrai coach` from a
terminal opens the agent without the dock.

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

Removes the symlinks that point into this plugin (other files of the same name
stay), the config dir, the connection file and the cache dir, plus the plugin
registration with Omarchy.
The plugin does not add anything to the Omarchy menu. Versions before 0.4.0
added a Fitness section; `install.sh` and `uninstall.sh` both remove it.

Does **not** touch the Setrai server or any API keys you've created
server-side — revoke those under **Settings > API keys** in the Setrai
web UI if you want them gone.

## Repository layout

```
manifest.json              Plugin manifest (kinds:[service, bar-widget])
Service.qml                Background poller + connection store
BarWidget.qml              The bar icon
Panel.qml                  The click-to-open popover
CoachDock.qml              Setrai docked beside the coach terminal
ReadinessView.qml          Overall readiness figure
BodyChart.qml              Latest body weight, total change, trend line, entry field
SettingsView.qml           Server address, API key and refresh form
Model.js                   Pure-JS helpers (parsing and formatting only)
bin/setrai                 CLI wrapper used by the popover + desktop entry
bin/setrai-read / -write / -upload
                           The only way the skills reach the Setrai API
bin/setrai-open.sh         URL opener the Panel shells out to (calls bin/setrai)
setrai.desktop.in          Launcher template (install.sh fills in the CLI path)
hooks/post-boot.sh         Optional Docker-stack autostart
agent-skill/               Eight SKILL.md files for AI coaches
install.sh / uninstall.sh  Idempotent install, clean uninstall
```

## License

MIT — see `LICENSE`.
