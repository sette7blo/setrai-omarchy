// Live-reactive palette reader for the Omarchy active theme.
//
// Prefer the Quickshell `bar.foreground` / `bar.background` / `bar.accent`
// primitives that the Omarchy Quattro runtime already exposes — they handle
// theme switching for free and are what BarWidget.qml and Panel.qml consume
// by default.
//
// This component is here for palette slots that Quickshell does NOT surface
// (e.g. `fgDim`, `bgAlt`), by tailing Omarchy's theme TOML and parsing a
// handful of keys. Falls back to a safe neutral palette if the file is
// missing or malformed — never crashes.
//
// Semantic colors (readiness traffic-light: red / amber / green) are
// intentionally NOT read from the theme and stay as themeColors.readyColor /
// midColor / lowColor, because they carry meaning independent of the user's
// theme accent.
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: themeColors

  readonly property string statePath:
    (Quickshell.env("HOME") || "") + "/.local/state/omarchy/current/theme/colors.toml"

  // Fallback palette — dark neutral, used when colors.toml is missing or the
  // parse fails. Keep in sync with the dark Omarchy defaults.
  property color fallbackFg:    "#e6e6e6"
  property color fallbackBg:    "#1a1b26"
  property color fallbackAccent: "#7aa2f7"

  // Read values, defaulting to fallbacks.
  property color fg:     fallbackFg
  property color bg:     fallbackBg
  property color accent: fallbackAccent
  property color fgDim:  Qt.rgba(fg.r, fg.g, fg.b, 0.58)
  property color bgAlt:  Qt.rgba(fg.r, fg.g, fg.b, 0.08)

  // Semantic traffic-light — stays theme-independent by design.
  readonly property color readyColor: "#63d297"
  readonly property color midColor:   "#e5c07b"
  readonly property color lowColor:   "#ff6b7a"

  function colorFor(readiness) {
    if (readiness === null || readiness === undefined) return fgDim
    var v = Number(readiness)
    if (v >= 0.75) return readyColor
    if (v >= 0.5)  return midColor
    return lowColor
  }

  function _stripQuotes(value) {
    var trimmed = String(value || "").trim()
    if ((trimmed.charAt(0) === '"' && trimmed.charAt(trimmed.length - 1) === '"') ||
        (trimmed.charAt(0) === "'" && trimmed.charAt(trimmed.length - 1) === "'")) {
      return trimmed.slice(1, -1)
    }
    return trimmed
  }

  function _parse(text) {
    // Flat `key = "#rrggbb"` lines — Omarchy's colors.toml has no tables we
    // care about. Anything else is ignored.
    var out = {}
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line || line.charAt(0) === "#") continue
      var eq = line.indexOf("=")
      if (eq < 0) continue
      var key = line.slice(0, eq).trim()
      var val = _stripQuotes(line.slice(eq + 1).split("#")[0])
      if (/^#[0-9a-fA-F]{3,8}$/.test(val)) out[key] = val
    }
    return out
  }

  property var _parsed: ({})

  function _apply() {
    var p = _parsed || {}
    fg     = p.foreground || p.fg || fallbackFg
    bg     = p.background || p.bg || fallbackBg
    accent = p.accent     || p.primary || fallbackAccent
  }

  property FileView _reader: FileView {
    path: themeColors.statePath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        themeColors._parsed = themeColors._parse(text())
      } catch (e) {
        console.warn("[setrai] theme parse failed:", e)
        themeColors._parsed = {}
      }
      themeColors._apply()
    }
    onLoadFailed: {
      themeColors._parsed = {}
      themeColors._apply()
    }
  }
}
