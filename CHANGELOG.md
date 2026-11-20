# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- "Ask coach" docks Setrai on the left edge of the screen and opens the coach terminal
  beside it on the same workspace. The dock reserves its width, so Hyprland tiles the
  terminal into the rest of the screen. It shows readiness, this week's sessions, volume
  and streak, the body weight chart, recent sessions and saved programs, and refreshes
  every 15 seconds so the coach's changes show up. It is shown only on the coach's
  workspace, and goes away when the coach terminal closes or with its close button.

### Changed
- The coach is off by default. Switch it on in Settings ("Enable the coach") to get the
  Ask coach button back; `setrai coach` in a terminal works either way.
- The coach opens the agent with its normal permission prompts. It used to go through
  `omarchy-agent`, which switches them off. It now supports claude, codex, cursor-agent
  and copilot; Settings and `setrai coach --check` say why it cannot open with any other.
- The skills reach Setrai through `bin/setrai-read` and `bin/setrai-write` instead of curl
  and the credentials file. The key no longer passes through the agent.
- Two more coach switches in Settings, off by default: "Read Setrai without asking" and
  "Change Setrai without asking". They pre-approve exactly those commands for the coach's
  session (claude, cursor-agent, copilot; codex still asks). The coach now starts in its own
  folder, `~/.local/state/omarchy/setrai/coach`.

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

[Unreleased]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.4...HEAD
[v0.4.4]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.3...v0.4.4
[v0.4.3]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.2...v0.4.3
[v0.4.2]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.1...v0.4.2
[v0.4.1]: https://github.com/sette7blo/setrai-omarchy/compare/v0.4.0...v0.4.1
[v0.4.0]: https://github.com/sette7blo/setrai-omarchy/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/sette7blo/setrai-omarchy/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/sette7blo/setrai-omarchy/releases/tag/v0.2.0
