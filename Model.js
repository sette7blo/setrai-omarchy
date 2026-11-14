// Pure-JS helpers shared by Service.qml, Panel.qml, BarWidget.qml and
// SettingsView.qml. Parsing and formatting only: every figure the plugin
// shows comes from Setrai's API as-is.

var PLUGIN_ID = "io.github.sette7blo.setrai"
var KEY_PREFIX = "setrai_"
var DEFAULT_POLL_SECONDS = 30
var MIN_POLL_SECONDS = 5
var MAX_POLL_SECONDS = 3600
var DEFAULT_BASE_URL = "http://localhost:3000"

// ----- Settings (persisted into the Omarchy bar layout entry) -------------
// Only the poll interval lives here. The server address is stored with the
// API key in the connection file so bin/setrai and the skills read the same
// value. `legacyBaseUrl` is what older versions saved here; Service.qml moves
// it into the connection file once.

function defaultSettings() {
  return { pollSeconds: DEFAULT_POLL_SECONDS, legacyBaseUrl: "" }
}

function clampPoll(value) {
  var n = parseInt(value, 10)
  if (!(n >= MIN_POLL_SECONDS)) return DEFAULT_POLL_SECONDS
  if (n > MAX_POLL_SECONDS) return MAX_POLL_SECONDS
  return n
}

function normalizeBaseUrl(value) {
  var s = String(value || "").replace(/^\s+|\s+$/g, "")
  if (!s) return ""
  // Strip trailing slash to make concatenation unambiguous.
  return s.replace(/\/+$/, "")
}

function normalizeSettings(raw) {
  var data = raw && typeof raw === "object" ? raw : {}
  return {
    pollSeconds: clampPoll(data.pollSeconds),
    legacyBaseUrl: normalizeBaseUrl(data.legacyBaseUrl !== undefined ? data.legacyBaseUrl : data.baseUrl)
  }
}

function pluginSettings(config, id) {
  var key = String(id || PLUGIN_ID)
  var empty = defaultSettings()
  if (!config || typeof config !== "object") return empty

  function fromEntry(entry) {
    if (!entry || typeof entry !== "object") return null
    if (String(entry.id || "") !== key) return null
    return normalizeSettings(entry)
  }

  var bar = config.bar && config.bar.layout ? config.bar.layout : {}
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var entries = bar[sections[s]] || []
    for (var i = 0; i < entries.length; i++) {
      var found = fromEntry(entries[i])
      if (found) return found
    }
  }
  var plugins = config.plugins || []
  for (var p = 0; p < plugins.length; p++) {
    var plugin = fromEntry(plugins[p])
    if (plugin) return plugin
  }
  return empty
}

function settingsPayload(settings) {
  var data = normalizeSettings(settings)
  return {
    id: PLUGIN_ID,
    pollSeconds: data.pollSeconds
  }
}

// ----- Connection (server address + API key, private state file) ----------

function emptyConnection() {
  return { baseUrl: "", apiKey: "" }
}

function cleanConnection(data) {
  return {
    baseUrl: normalizeBaseUrl(data.baseUrl),
    apiKey: String(data.apiKey || "")
  }
}

function parseConnection(raw) {
  try {
    var data = JSON.parse(String(raw || "{}"))
    if (!data || typeof data !== "object") return emptyConnection()
    return cleanConnection(data)
  } catch (e) {
    return emptyConnection()
  }
}

function serializeConnection(conn) {
  var data = conn && typeof conn === "object" ? conn : {}
  return JSON.stringify(cleanConnection(data), null, 2) + "\n"
}

function mergeConnection(conn, patch) {
  var current = conn && typeof conn === "object" ? conn : {}
  var extra = patch && typeof patch === "object" ? patch : {}
  var merged = {}
  for (var k in current) merged[k] = current[k]
  for (var p in extra) merged[p] = extra[p]
  return cleanConnection(merged)
}

function isValidKey(key) {
  var s = String(key || "")
  return s.indexOf(KEY_PREFIX) === 0 && s.length > KEY_PREFIX.length
}

// ----- HTTP helpers -------------------------------------------------------

function isHttpUrl(url) {
  return /^https?:\/\//.test(String(url || ""))
}

function apiUrl(base, path) {
  var root = normalizeBaseUrl(base)
  if (!root) return ""
  var p = String(path || "")
  if (!p) return root
  return root + (p.charAt(0) === "/" ? p : "/" + p)
}

function bearerHeaderText(apiKey) {
  var key = String(apiKey || "")
  return "Authorization: Bearer " + key + "\n"
    + "Accept: application/json\n"
}

// ----- Shell helpers (atomic private writes) ------------------------------

function leafName(filePath) {
  var parts = String(filePath || "").split("/")
  for (var i = 0; i < parts.length; i++) {
    if (parts[i] === "..") return ""
  }
  var name = parts.length ? parts[parts.length - 1] : ""
  if (!name || name === "." || name === ".." || name.indexOf("/") !== -1) return ""
  return name
}

function utf8ByteLength(text) {
  var s = String(text || "")
  var n = 0
  for (var i = 0; i < s.length; i++) {
    var c = s.charCodeAt(i)
    if (c < 128) n += 1
    else if (c < 2048) n += 2
    else if (c >= 0xD800 && c <= 0xDBFF) { n += 4; i++ }
    else n += 3
  }
  return n
}

function ensurePrivateDirsCmd(stateDir, cacheDir) {
  return ["sh", "-c",
    "ensure() {\n"
      + "  t=$1\n"
      + "  mkdir -p -- \"$(dirname -- \"$t\")\" || exit 1\n"
      + "  if [ -L \"$t\" ]; then exit 1; fi\n"
      + "  if [ -e \"$t\" ]; then [ -d \"$t\" ] || exit 1; else mkdir -m 700 -- \"$t\" || exit 1; fi\n"
      + "  chmod 700 -- \"$t\" || exit 1\n"
      + "}\n"
      + "ensure \"$1\"\n"
      + "ensure \"$2\"\n",
    "setrai-dirs", String(stateDir || ""), String(cacheDir || "")]
}

function atomicWriteCmd(dir, name, bytes) {
  var leaf = leafName(name)
  var n = parseInt(bytes, 10)
  if (!leaf || leaf !== String(name || "") || !(n >= 0)) return ["sh", "-c", "exit 1"]
  return ["sh", "-c",
    "dir=$1; name=$2; n=$3\n"
      + "[ -d \"$dir\" ] && [ ! -L \"$dir\" ] || exit 1\n"
      + "umask 077\n"
      + "tmp=$(mktemp -p \"$dir\" .tmp.XXXXXX) || exit 1\n"
      + "trap 'rm -f \"$tmp\"' EXIT\n"
      + "head -c \"$n\" > \"$tmp\" || exit 1\n"
      + "[ \"$(wc -c < \"$tmp\")\" -eq \"$n\" ] || exit 1\n"
      + "chmod 600 -- \"$tmp\" || exit 1\n"
      + "mv -f -T -- \"$tmp\" \"$dir/$name\" || exit 1\n"
      + "trap - EXIT\n",
    "setrai-write", String(dir || ""), leaf, String(n)]
}

// ----- API response parsing ----------------------------------------------

function parseJsonSafe(text, fallback) {
  try {
    var data = JSON.parse(String(text || ""))
    return data === null || data === undefined ? fallback : data
  } catch (e) {
    return fallback
  }
}

function finiteOrNull(value) {
  if (value === null || value === undefined || value === "") return null
  var n = Number(value)
  return isFinite(n) ? n : null
}

function parseSessions(text) {
  var data = parseJsonSafe(text, {})
  return Array.isArray(data && data.sessions) ? data.sessions : []
}

// GET /api/recovery -> { recovery: { readiness: <whole %>, ... } }
function parseRecovery(text) {
  var data = parseJsonSafe(text, {})
  var recovery = data && data.recovery ? data.recovery : {}
  return { readiness: finiteOrNull(recovery.readiness) }
}

// GET /api/statistics -> { statistics: { weeklyVolume, trainingFrequency,
// bodyWeight, bodyWeightChangeKg, ... } }
function parseStatistics(text) {
  var data = parseJsonSafe(text, {})
  var stats = data && data.statistics ? data.statistics : {}
  var weekly = []
  if (Array.isArray(stats.weeklyVolume)) {
    for (var i = 0; i < stats.weeklyVolume.length; i++) {
      var w = stats.weeklyVolume[i]
      var v = finiteOrNull(w && w.volume)
      if (w && w.weekStart && v !== null) weekly.push({ weekStart: String(w.weekStart), volume: v })
    }
  }
  var body = []
  if (Array.isArray(stats.bodyWeight)) {
    for (var j = 0; j < stats.bodyWeight.length; j++) {
      var e = stats.bodyWeight[j]
      var kg = finiteOrNull(e && e.weightKg)
      if (e && e.date && kg !== null) body.push({ date: String(e.date), weightKg: kg })
    }
  }
  var freq = stats.trainingFrequency || {}
  return {
    weeklyVolume: weekly,
    sessionsThisWeek: finiteOrNull(freq.thisWeek) || 0,
    bodyWeight: body,
    bodyWeightChangeKg: finiteOrNull(stats.bodyWeightChangeKg)
  }
}

function parseProfile(text) {
  var data = parseJsonSafe(text, {})
  var profile = data && data.profile ? data.profile : {}
  return { weightUnit: profile.weightUnit === "lb" ? "lb" : "kg" }
}

function parseApiKeyProbe(text) {
  var data = parseJsonSafe(text, null)
  if (!data || !data.apiKey) return null
  var k = data.apiKey
  return {
    name: String(k.name || ""),
    prefix: String(k.prefix || ""),
    scope: String(k.scope || "")
  }
}

// ----- Lookups over fetched data ------------------------------------------

function parseTimestamp(value) {
  if (!value) return null
  var s = String(value)
  var iso = s.indexOf("T") >= 0 ? s : s.replace(" ", "T") + "Z"
  var parsed = new Date(iso)
  return isNaN(parsed.getTime()) ? null : parsed
}

// Monday-based UTC week key, the same key Setrai uses for weeklyVolume.
function weekKey(date) {
  var start = new Date(Date.UTC(
    date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()
  ))
  var day = start.getUTCDay() || 7
  start.setUTCDate(start.getUTCDate() - day + 1)
  return start.toISOString().slice(0, 10)
}

// The server omits weeks without volume, so a missing current week is 0.
function currentWeekVolume(weeklyVolume, now) {
  var key = weekKey(now || new Date())
  var list = Array.isArray(weeklyVolume) ? weeklyVolume : []
  for (var i = 0; i < list.length; i++) {
    if (list[i].weekStart === key) return list[i].volume
  }
  return 0
}

function openWorkout(sessions) {
  var list = Array.isArray(sessions) ? sessions : []
  for (var i = 0; i < list.length; i++) {
    var s = list[i]
    if (s && !s.finishedAt) {
      return {
        sessionId: s.id,
        url: "/sessions/" + s.id,
        programName: String(s.programName || "")
      }
    }
  }
  return null
}

function lastFinishedAt(sessions) {
  var list = Array.isArray(sessions) ? sessions : []
  var latest = null
  for (var i = 0; i < list.length; i++) {
    var t = parseTimestamp(list[i] && list[i].finishedAt)
    if (t && (!latest || t > latest)) latest = t
  }
  return latest ? latest.toISOString() : ""
}

function latestBodyEntry(entries) {
  if (!Array.isArray(entries) || !entries.length) return null
  return entries[entries.length - 1]
}

// ----- Formatting --------------------------------------------------------

// Setrai stores every weight in kg. The profile's weightUnit only changes how
// a value is written out and typed in; the factor is the web app's.
var LB_PER_KG = 2.2046226218

function weightUnit(unit) {
  return unit === "lb" ? "lb" : "kg"
}

function inUnit(kg, unit) {
  return weightUnit(unit) === "lb" ? Number(kg) * LB_PER_KG : Number(kg)
}

function formatVolume(kg, unit) {
  var u = weightUnit(unit)
  var n = inUnit(kg, u)
  if (!(n > 0)) return "0 " + u
  if (u === "kg" && n >= 1000) return (n / 1000).toFixed(1) + " t"
  // Grouped by hand: QML's Number.toLocaleString does not take a locale name.
  return String(Math.round(n)).replace(/\B(?=(\d{3})+$)/g, ",") + " " + u
}

function formatWeight(kg, unit) {
  if (kg === null || kg === undefined || !isFinite(Number(kg))) return "-"
  return inUnit(kg, unit).toFixed(1) + " " + weightUnit(unit)
}

function formatChange(kg, unit) {
  if (kg === null || kg === undefined || !isFinite(Number(kg))) return ""
  var n = inUnit(kg, unit)
  if (Math.abs(n) < 0.05) return "No change"
  return (n > 0 ? "+" : "\u2212") + Math.abs(n).toFixed(1) + " " + weightUnit(unit)
}

// ----- Body-weight entry -------------------------------------------------

// Reads what the user typed in their own unit. Returns the kg value the API
// takes, or a message saying why nothing can be sent.
function parseWeightInput(text, unit) {
  var raw = String(text === null || text === undefined ? "" : text).trim().replace(",", ".")
  if (!raw) return { weightKg: null, error: "Enter your weight" }
  if (!/^\d+(\.\d+)?$/.test(raw)) return { weightKg: null, error: "Enter a number, such as 72.4" }
  var n = Number(raw)
  if (!(n > 0)) return { weightKg: null, error: "Weight must be greater than zero" }
  var kg = weightUnit(unit) === "lb" ? n / LB_PER_KG : n
  return { weightKg: Math.round(kg * 100) / 100, error: "" }
}

function localDateKey(date) {
  var d = date || new Date()
  function pad(v) { return (v < 10 ? "0" : "") + v }
  return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
}

function bodyWeightBody(weightKg, date) {
  return JSON.stringify({ date: localDateKey(date), weightKg: Number(weightKg) })
}

function parseErrorMessage(text) {
  var data = parseJsonSafe(text, {})
  return data && typeof data.error === "string" ? data.error : ""
}

function formatReadinessPct(value) {
  if (value === null || value === undefined || !isFinite(Number(value))) return "-"
  return Math.round(Number(value)) + "%"
}

function formatSessions(count) {
  var n = Number(count) || 0
  return n + (n === 1 ? " session" : " sessions")
}

function relativeDay(iso, now) {
  var t = parseTimestamp(iso)
  if (!t) return ""
  var ref = now || new Date()
  var a = new Date(ref.getFullYear(), ref.getMonth(), ref.getDate())
  var b = new Date(t.getFullYear(), t.getMonth(), t.getDate())
  var d = Math.round((a - b) / 86400000)
  if (d <= 0) return "today"
  if (d === 1) return "yesterday"
  if (d < 14) return d + " days ago"
  if (d < 60) return Math.round(d / 7) + " weeks ago"
  return Math.round(d / 30) + " months ago"
}

// QML `import "Model.js" as Model` picks up every top-level `var` and
// `function` as `Model.foo`. The block below is for Node-based tests only.

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    PLUGIN_ID: PLUGIN_ID,
    KEY_PREFIX: KEY_PREFIX,
    DEFAULT_BASE_URL: DEFAULT_BASE_URL,
    DEFAULT_POLL_SECONDS: DEFAULT_POLL_SECONDS,
    MIN_POLL_SECONDS: MIN_POLL_SECONDS,
    MAX_POLL_SECONDS: MAX_POLL_SECONDS,
    defaultSettings: defaultSettings,
    normalizeSettings: normalizeSettings,
    normalizeBaseUrl: normalizeBaseUrl,
    pluginSettings: pluginSettings,
    settingsPayload: settingsPayload,
    emptyConnection: emptyConnection,
    parseConnection: parseConnection,
    serializeConnection: serializeConnection,
    mergeConnection: mergeConnection,
    isValidKey: isValidKey,
    isHttpUrl: isHttpUrl,
    apiUrl: apiUrl,
    bearerHeaderText: bearerHeaderText,
    utf8ByteLength: utf8ByteLength,
    ensurePrivateDirsCmd: ensurePrivateDirsCmd,
    atomicWriteCmd: atomicWriteCmd,
    parseSessions: parseSessions,
    parseRecovery: parseRecovery,
    parseStatistics: parseStatistics,
    parseApiKeyProbe: parseApiKeyProbe,
    parseTimestamp: parseTimestamp,
    weekKey: weekKey,
    currentWeekVolume: currentWeekVolume,
    openWorkout: openWorkout,
    lastFinishedAt: lastFinishedAt,
    latestBodyEntry: latestBodyEntry,
    LB_PER_KG: LB_PER_KG,
    parseProfile: parseProfile,
    formatVolume: formatVolume,
    formatWeight: formatWeight,
    formatChange: formatChange,
    parseWeightInput: parseWeightInput,
    localDateKey: localDateKey,
    bodyWeightBody: bodyWeightBody,
    parseErrorMessage: parseErrorMessage,
    formatReadinessPct: formatReadinessPct,
    formatSessions: formatSessions,
    relativeDay: relativeDay
  }
}
