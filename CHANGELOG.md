# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed
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

[Unreleased]: https://github.com/sette7blo/setrai-omarchy/compare/v0.2.0...HEAD
[v0.2.0]: https://github.com/sette7blo/setrai-omarchy/releases/tag/v0.2.0
