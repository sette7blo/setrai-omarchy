# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [v0.8.0] - 2026-11-24

### Security
- The API key is sent to curl on stdin by every request (popover, Test
  connection, `setrai start`/`quick`/`body`), never on a command line, and the
  popover no longer keeps it in a header file.
- Every keyed request ignores `~/.curlrc` and refuses redirects, so a redirect
  can no longer carry the key to another address.
- The address and key of a request come from one saved connection: changing
  the address no longer sends the old key to the new server, and an answer from
  the old server is dropped.
- Plain `http://` to another machine needs the new Settings switch **Send the
  key over plain http**, given for that address only. `localhost` and
  `127.x.x.x` are unaffected.
- Settings and body-weight text fields no longer read the clipboard while they
  are not being typed in (a slow clipboard offer could stall the shell).
- `setrai-upload` checks and reads the image through one open handle.

### Changed
- `install.sh` links the agent skills only with `--skills`. The coach does not
  need the links.
- `SETRAI_URL` and `SETRAI_API_KEY` no longer override the saved connection.

### Fixed
- `uninstall.sh` also removes the `setrai-create-exercise` skill link.

### Upgrading
- If your Setrai address is plain http on another machine, open Settings,
  switch on **Send the key over plain http** and save. Until then the
  popover shows a notice and sends nothing.

## [v0.7.1] - 2026-11-21

### Changed
- `setrai-create-exercise` says when to leave secondary muscles empty: Setrai's
  recovery counts each one at half load, so the coach lists only muscles that do real
  work, and no longer adds forearms for grip (recovery counts them as biceps).

## [v0.7.0] - 2026-11-21

### Added
- New `setrai-create-exercise` skill: the coach checks the library, creates a missing
  exercise with Setrai's allowed categories, muscles and equipment, then generates its
  picture in the library's style and attaches it with `setrai-upload`. It carries a
  written style guide and four library pictures as references, retries a wrong pose,
  and says so instead of drawing a substitute when the agent cannot generate images.
  The program skill now offers it when the library lacks an exercise. After updating,
  run `./install.sh` again to link the new skill for agents used outside the coach.

## [v0.6.0] - 2026-11-21

### Added
- `setrai-upload <exercise-id> <image-file>` uploads a JPEG, PNG, WebP or GIF of up to
  10 MB and sets it as the exercise's picture, so the coach can attach an image it made.
  It checks the file's first bytes, refuses SVG, and checks the exercise exists before
  uploading. "Change without asking" pre-approves it along with `setrai-write`.
  Needs Setrai v0.8.3 or later; older servers fail every image upload.

### Changed
- Requests to Setrai ignore `~/.curlrc`, so a curl config cannot add redirects or
  another host to a request that carries the API key.

## [v0.5.0] - 2026-11-21

### Added
- "Ask coach" opens the coach on the first empty workspace of the current screen, with
  Setrai docked on the left edge and the coach terminal beside it. The dock reserves its
  width, so Hyprland tiles the terminal into the rest of the screen. It shows readiness,
  this week's sessions, volume and streak, the body weight chart, recent sessions and
  saved programs, and refreshes every 15 seconds so the coach's changes show up. It is shown only on the coach's
  workspace. Dock and terminal close together, from either one, and asking again while
  the coach is open goes back to it.
- `setrai-read /api/<path> --jq '<filter>'` keeps only the fields the coach needs from a
  large answer, so it does not run python or jq itself, which would each ask for
  approval. The filter runs with an empty environment and may not import files.

### Changed
- The coach is off by default. Switch it on in Settings ("Ask coach") to get the
  Ask coach button back; `setrai coach` in a terminal works either way.
- The coach opens the agent with its normal permission prompts. It used to go through
  `omarchy-agent`, which switches them off. It now supports claude, codex, cursor-agent
  and copilot; Settings and `setrai coach --check` say why it cannot open with any other.
- The skills reach Setrai through `bin/setrai-read` and `bin/setrai-write` instead of curl
  and the credentials file. The key no longer passes through the agent.
- Two more coach switches in Settings, off by default: "Read without asking" and
  "Change without asking". They pre-approve exactly those commands for the coach's
  session (claude, cursor-agent, copilot; codex still asks). The coach now starts in its own
  folder, `~/.local/state/omarchy/setrai/coach`.
- Settings are grouped into Connection and AI coach, the panel is wider while they are
  open, and they scroll when they do not fit.

## [v0.4.4] - 2026-11-18

### Fixed
- The launcher (`setrai.desktop`) runs the plugin's own `bin/setrai` instead of `~/.local/bin/setrai`,
  which may belong to another program when the installer left it alone. Run `install.sh` again to rewrite a launcher written by an earlier version.
  If the plugin folder's path holds characters a launcher cannot carry safely, no
  launcher is made.

## [v0.4.3] - 2026-11-18

### Fixed
- The installer no longer moves an existing `~/.local/bin/setrai`, `setrai.desktop` or agent
  skill aside to put its own link there. A path that is already taken is left as it is,
  and the plugin works without the link. The uninstaller removes only links that point
  into the plugin. Backups made by earlier versions (`*.bak.<date>`) are not touched.

## [v0.4.2] - 2026-11-15

### Added
- The manifest names a Monero address for tips (`"funding": { "monero": "..." }`), so
  wallets and plugin managers that read it can offer a tip to the author.

## [v0.4.1] - 2026-11-15

### Changed
- "Start workout" lists your saved programs inside the popover instead of opening the Omarchy
  menu as a picker. `setrai start` in a terminal still asks with a numbered list.

## [v0.4.0] - 2026-11-15

### Removed
- The Fitness section in the Omarchy menu. The popover already covers opening Setrai, starting
  a workout, logging body weight and asking the coach, and the plugin no longer edits
  `~/.config/omarchy/extensions/omarchy-menu.jsonc`. Run `install.sh` again to take the section
  out of your menu. Quick workout and the Statistics page stay available as `setrai quick` and
  `setrai stats`.

## [v0.3.0] - 2026-11-15

### Added
- Log today's body weight from the popover: type it in the body-weight section and press
  Enter. Logging again the same day replaces the entry.
- Start a workout from a saved program: `setrai start`, "Start workout" in the Fitness menu
  and a button in the popover ask which program, start the session and open it. If a workout
  is already in progress it is opened instead of starting a second one.
- "Ask coach" in the Fitness menu (`setrai coach`) opens your default Omarchy agent with your
  Setrai data and skills at hand. It is hidden until a default agent is set.
- An "Ask coach" button in the popover does the same.
- Two agent skills: `setrai-create-program` designs a program with you and saves it, and
  `setrai-weekly-review` reads the week's sessions and suggests what to adjust. Run
  `install.sh` again to link them.

### Changed
- Weights follow the unit set in your Setrai profile. With `lb`, the popover shows body
  weight, its change and weekly volume in pounds, and `setrai body` takes pounds. Setrai
  still stores kilograms.
- Setrai opens in its own window (`omarchy-launch-webapp`) instead of a browser tab.
- `setrai quick` opens the session it started instead of the home page.

### Fixed
- The Fitness menu never appeared: Omarchy reads one menu file, and the entries were linked
  beside it. `install.sh` now merges them into `~/.config/omarchy/extensions/omarchy-menu.jsonc`
  as a marked block, and `uninstall.sh` removes the block. Run `install.sh` again.
- `setrai coach` says so when the default agent is not installed instead of doing nothing.
- "Log body weight" in the Fitness menu did nothing. It now asks for the weight in an
  Omarchy menu prompt and confirms with a notification.
- `setrai body` rejects values that are not a positive number instead of sending them.
- The quick-workout skill documented request fields the server ignores, so requests such as
  "30 minutes, push" returned a default workout. It now documents `durationMinutes`, `goal`,
  `targetMuscles` and `equipment`.

## [v0.2.0] - 2026-11-14

First tagged release. Requires Setrai v0.8.0 or newer.

### Added
- Bar widget with a dumbbell icon, and a resume indicator while a workout is in progress.
- Popover showing readiness, when you last trained, this week's session count and volume,
  and body weight with its total change and a full-history trend line.
- Omarchy menu entries, the `setrai` command line helper and agent skills for logging body
  weight, starting a workout, quick workouts, recovery and statistics.
- Theme sync with the active Omarchy theme.

### Changed
- The plugin only reads `GET /api/sessions`, `GET /api/recovery` and `GET /api/statistics`
  with an API key, and shows the values the server returns instead of calculating its own.
- The Setrai address and API key are stored together in
  `~/.local/state/omarchy/setrai/credentials.json`, shared by the plugin, `bin/setrai`, the
  launcher and the agent skills. An address saved in the bar config by an earlier version is
  moved there automatically. `install.sh --setrai-url` pre-fills it.

### Removed
- The Today row, the guessed active program, the per-muscle recovery list and the 1W/2W/4W
  body-weight switch.
- Use of the `/api/omarchy/snapshot` endpoint.

[Unreleased]: https://github.com/sette7blo/setrai-omarchy/compare/v0.8.0...HEAD
[v0.8.0]: https://github.com/sette7blo/setrai-omarchy/compare/v0.7.1...v0.8.0
[v0.7.1]: https://github.com/sette7blo/setrai-omarchy/compare/v0.7.0...v0.7.1
[v0.7.0]: https://github.com/sette7blo/setrai-omarchy/compare/v0.6.0...v0.7.0
[v0.6.0]: https://github.com/sette7blo/setrai-omarchy/compare/v0.5.0...v0.6.0
[v0.5.0]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.4...v0.5.0
[v0.4.4]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.3...v0.4.4
[v0.4.3]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.2...v0.4.3
[v0.4.2]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.1...v0.4.2
[v0.4.1]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.0...v0.4.1
[v0.4.0]: https://github.com/sette7blo/setrai-omarchy/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/sette7blo/setrai-omarchy/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/sette7blo/setrai-omarchy/releases/tag/v0.2.0
