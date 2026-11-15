import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// Background service: polls Setrai's REST API with an API key and exposes
// the values it returns (readiness, this week's sessions and volume, body
// weight, an open workout) to the bar widget and the panel. It also sends
// the one thing the panel can enter, today's body weight. Nothing here
// computes a figure the server does not already provide.
Item {
  id: root

  property var shell: null
  property bool panelOpen: false

  // --- Persistent settings (bar layout entry) ------------------------------
  property var pluginSettings: Model.pluginSettings(null, Model.PLUGIN_ID)
  readonly property int pollSeconds: pluginSettings.pollSeconds

  // --- Connection (private state file, shared with bin/setrai) -------------
  property var connection: Model.emptyConnection()
  property bool connectionLoaded: false
  readonly property string baseUrl: String(connection.baseUrl || "")
  readonly property string apiKey: String(connection.apiKey || "")
  readonly property bool hasKey: Model.isValidKey(apiKey)
  readonly property bool configured: Model.isHttpUrl(baseUrl) && hasKey

  // --- Filesystem layout ---------------------------------------------------
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string stateDir: home + "/.local/state/omarchy/setrai"
  readonly property string cacheDir: home + "/.cache/omarchy/setrai"
  readonly property string connectionPath: stateDir + "/credentials.json"
  readonly property string headerPath: cacheDir + "/header.txt"

  // --- Fetched state exposed to widget/panel -------------------------------
  property var sessions: []
  property var readiness: null              // whole %, from /api/recovery
  property var statistics: Model.parseStatistics("")
  property string weightUnit: "kg"          // "kg" | "lb", from /api/profile
  property string lastUpdatedAt: ""
  property string status: "idle"
  // "idle" | "polling" | "ok" | "unauthorized" | "unreachable" | "unconfigured" | "error"
  property string statusDetail: ""

  readonly property var openWorkout: Model.openWorkout(sessions)
  readonly property string lastWorkoutAt: Model.lastFinishedAt(sessions)
  readonly property int sessionsThisWeek: statistics.sessionsThisWeek
  readonly property real weekVolumeKg: Model.currentWeekVolume(statistics.weeklyVolume, new Date())
  readonly property var bodyEntries: statistics.bodyWeight
  readonly property var bodyChangeKg: statistics.bodyWeightChangeKg

  // --- Settings test-connection result (SettingsView listens) --------------
  signal connectionProbed(bool ok, string message, var info)

  // --- Body-weight entry result (BodyChart listens) -------------------------
  property bool savingBodyWeight: false
  signal bodyWeightSaved(bool ok, string message)

  // --- Internal state ------------------------------------------------------
  property bool dirsReady: false
  property bool headerReady: false
  property var writeQueue: []
  property string pendingWriteText: ""
  property string pendingWriteThen: ""
  property var reqQueue: []
  property var currentReq: null
  property bool probing: false

  // --- Plugin settings load ------------------------------------------------
  function loadSettings() {
    var sh = root.shell
    var cfg = sh ? (sh.shellConfig || (sh.barConfig ? { bar: sh.barConfig } : null)) : null
    var next = Model.pluginSettings(cfg, Model.PLUGIN_ID)
    if (JSON.stringify(next) !== JSON.stringify(root.pluginSettings)) root.pluginSettings = next
    root.migrateLegacyUrl()
  }

  // Older versions kept the server address in the bar entry. Move it into
  // the connection file once, so the CLI and skills see the same address.
  function migrateLegacyUrl() {
    var legacy = root.pluginSettings.legacyBaseUrl
    if (!root.connectionLoaded || !legacy || root.baseUrl) return
    root.persistConnection({ baseUrl: legacy })
  }

  function persistSettings(patch) {
    var current = Model.normalizeSettings(root.pluginSettings)
    var extra = patch && typeof patch === "object" ? patch : {}
    for (var k in extra) current[k] = extra[k]
    current = Model.normalizeSettings(current)
    var payload = Model.settingsPayload(current)
    if (root.shell && typeof root.shell.updateEntryInline === "function")
      root.shell.updateEntryInline(Model.PLUGIN_ID, payload)
    root.pluginSettings = current
  }

  // --- Connection write (atomic, chmod 600) --------------------------------
  function persistConnection(patch) {
    root.connection = Model.mergeConnection(root.connection, patch)
    enqueueWrite(root.stateDir, "credentials.json", Model.serializeConnection(root.connection), "connection")
  }

  function enqueueWrite(dir, name, text, thenKind) {
    root.writeQueue = root.writeQueue.concat([{
      dir: dir, name: name, text: String(text || ""), thenKind: String(thenKind || "")
    }])
    pumpWrites()
  }

  function pumpWrites() {
    if (secretProc.running || !root.writeQueue.length) return
    var next = root.writeQueue[0]
    root.writeQueue = root.writeQueue.slice(1)
    root.pendingWriteText = next.text
    root.pendingWriteThen = next.thenKind
    secretProc.command = Model.atomicWriteCmd(next.dir, next.name, Model.utf8ByteLength(next.text))
    secretProc.running = true
  }

  // --- Header refresh ------------------------------------------------------
  function refreshHeader() {
    if (!root.dirsReady) return
    if (!root.hasKey) { root.headerReady = false; return }
    var text = Model.bearerHeaderText(root.apiKey)
    enqueueWrite(root.cacheDir, "header.txt", text, "header")
  }

  // --- HTTP request queue --------------------------------------------------
  function enqueueRequest(kind) {
    if (!root.configured || !root.headerReady) return
    for (var i = 0; i < root.reqQueue.length; i++) {
      if (root.reqQueue[i].kind === kind) return  // already pending
    }
    var pathForKind = {
      "sessions": "/api/sessions",
      "recovery": "/api/recovery",
      "statistics": "/api/statistics",
      "profile": "/api/profile"
    }
    var path = pathForKind[kind] || ""
    if (!path) return
    root.reqQueue = root.reqQueue.concat([{ kind: kind, url: Model.apiUrl(root.baseUrl, path) }])
    pump()
  }

  function forcePoll() {
    if (!root.configured) {
      root.status = "unconfigured"
      return
    }
    enqueueRequest("sessions")
    enqueueRequest("recovery")
    enqueueRequest("statistics")
    enqueueRequest("profile")
  }

  function pump() {
    if (apiProc.running || !root.reqQueue.length || !root.dirsReady || !root.headerReady) return
    var next = root.reqQueue[0]
    root.reqQueue = root.reqQueue.slice(1)
    root.currentReq = next
    root.status = "polling"
    apiProc.command = [
      "curl", "-sS", "-m", "15", "-w", "\n%{http_code}",
      "--proto", "=http,https",
      "-H", "@" + root.headerPath,
      "--", next.url
    ]
    apiProc.running = true
  }

  function handleResponse(kind, statusCode, body) {
    if (statusCode === 401 || statusCode === 403) {
      root.status = "unauthorized"
      root.statusDetail = "API key was rejected (" + statusCode + ")"
      root.reqQueue = []  // don't hammer the server with the same bad key
      return
    }
    if (statusCode < 200 || statusCode >= 400) {
      root.status = "error"
      root.statusDetail = "HTTP " + statusCode + " on " + kind
      return
    }
    if (kind === "sessions") root.sessions = Model.parseSessions(body)
    else if (kind === "recovery") root.readiness = Model.parseRecovery(body).readiness
    else if (kind === "statistics") root.statistics = Model.parseStatistics(body)
    else if (kind === "profile") root.weightUnit = Model.parseProfile(body).weightUnit
    root.lastUpdatedAt = new Date().toISOString()
    if (!root.reqQueue.length) {
      root.status = "ok"
      root.statusDetail = ""
    }
  }

  // --- Body-weight entry ---------------------------------------------------
  // `text` is what the user typed, in their own unit. The entry is saved for
  // today's local date; Setrai replaces an entry that already exists for it.
  function logBodyWeight(text) {
    if (root.savingBodyWeight) return
    var parsed = Model.parseWeightInput(text, root.weightUnit)
    if (parsed.error) {
      root.bodyWeightSaved(false, parsed.error)
      return
    }
    if (!root.configured || !root.headerReady) {
      root.bodyWeightSaved(false, "Connect your Setrai server first.")
      return
    }
    root.savingBodyWeight = true
    // The key stays in the private header file; the body holds no secret.
    postProc.command = [
      "curl", "-sS", "-m", "15", "-w", "\n%{http_code}",
      "--proto", "=http,https",
      "-H", "@" + root.headerPath,
      "-H", "Content-Type: application/json",
      "-X", "POST",
      "--data-raw", Model.bodyWeightBody(parsed.weightKg, new Date()),
      "--", Model.apiUrl(root.baseUrl, "/api/body-weight")
    ]
    postProc.running = true
  }

  // --- Test-connection one-shot (used by SettingsView) ---------------------
  // Does not touch the main poll queue; writes a temporary probe header file
  // so the Save button hasn't been pressed yet.
  function testConnection(testBaseUrl, testKey) {
    var url = Model.apiUrl(testBaseUrl, "/api/api-keys/current")
    if (!Model.isHttpUrl(url) || !Model.isValidKey(testKey)) {
      root.connectionProbed(false, "Enter the server address and an API key that starts with setrai_", null)
      return
    }
    if (root.probing) return
    root.probing = true
    probeProc.command = [
      "curl", "-sS", "-m", "10", "-w", "\n%{http_code}",
      "--proto", "=http,https",
      "-H", "Authorization: Bearer " + testKey,
      "-H", "Accept: application/json",
      "--", url
    ]
    probeProc.running = true
  }

  // --- Processes -----------------------------------------------------------
  Process {
    id: ensureDirProc
    running: false
    onExited: function(code) {
      if (code === 0) {
        root.dirsReady = true
        connectionFile.reload()
        root.refreshHeader()
      } else {
        root.status = "error"
        root.statusDetail = "Could not create " + root.stateDir
      }
    }
  }

  Process {
    id: secretProc
    running: false
    stdinEnabled: true
    onRunningChanged: {
      if (running) secretProc.write(root.pendingWriteText)
    }
    onExited: function(code) {
      var then = root.pendingWriteThen
      root.pendingWriteText = ""
      root.pendingWriteThen = ""
      if (code !== 0) {
        root.status = "error"
        root.statusDetail = "Failed to write private file (" + then + ")"
      } else if (then === "header") {
        root.headerReady = true
        root.forcePoll()
      } else if (then === "connection") {
        // connectionFile's watchChanges handles the reload; refresh the header too.
        root.refreshHeader()
      }
      Qt.callLater(root.pumpWrites)
      Qt.callLater(root.pump)
    }
  }

  Process {
    id: apiProc
    running: false
    stdout: StdioCollector { id: apiOut; waitForEnd: true }
    onExited: function(code) {
      var raw = String(apiOut.text || "")
      var req = root.currentReq
      root.currentReq = null
      if (code !== 0) {
        root.status = "unreachable"
        root.statusDetail = "curl exit " + code
        root.reqQueue = []
      } else {
        var lastNewline = raw.lastIndexOf("\n")
        var statusCode = lastNewline >= 0 ? parseInt(raw.slice(lastNewline + 1), 10) : 0
        var body = lastNewline >= 0 ? raw.slice(0, lastNewline) : raw
        if (!(statusCode > 0)) {
          root.status = "error"
          root.statusDetail = "Unparseable response"
        } else if (req) {
          root.handleResponse(req.kind, statusCode, body)
        }
      }
      Qt.callLater(root.pump)
    }
  }

  Process {
    id: postProc
    running: false
    stdout: StdioCollector { id: postOut; waitForEnd: true }
    onExited: function(code) {
      root.savingBodyWeight = false
      var raw = String(postOut.text || "")
      if (code !== 0) {
        root.bodyWeightSaved(false, "Setrai is not responding. Nothing was saved.")
        return
      }
      var lastNewline = raw.lastIndexOf("\n")
      var statusCode = lastNewline >= 0 ? parseInt(raw.slice(lastNewline + 1), 10) : 0
      var body = lastNewline >= 0 ? raw.slice(0, lastNewline) : raw
      if (statusCode >= 200 && statusCode < 300) {
        root.bodyWeightSaved(true, "")
        root.enqueueRequest("statistics")
      } else if (statusCode === 401 || statusCode === 403) {
        root.bodyWeightSaved(false, "Setrai did not accept the API key.")
      } else {
        root.bodyWeightSaved(false, Model.parseErrorMessage(body) || "Setrai returned HTTP " + statusCode + ".")
      }
    }
  }

  Process {
    id: probeProc
    running: false
    stdout: StdioCollector { id: probeOut; waitForEnd: true }
    onExited: function(code) {
      root.probing = false
      var raw = String(probeOut.text || "")
      if (code !== 0) {
        root.connectionProbed(false, "Could not reach the server. Check the address and that Setrai is running.", null)
        return
      }
      var lastNewline = raw.lastIndexOf("\n")
      var statusCode = lastNewline >= 0 ? parseInt(raw.slice(lastNewline + 1), 10) : 0
      var body = lastNewline >= 0 ? raw.slice(0, lastNewline) : raw
      if (statusCode === 200) {
        var info = Model.parseApiKeyProbe(body)
        root.connectionProbed(true, info && info.name
          ? "Connected with key \"" + info.name + "\""
          : "Connected", info)
      } else if (statusCode === 401 || statusCode === 403) {
        root.connectionProbed(false, "Setrai did not accept this API key.", null)
      } else if (!(statusCode > 0)) {
        root.connectionProbed(false, "The server did not respond like Setrai. Check the address.", null)
      } else {
        root.connectionProbed(false, "Setrai returned HTTP " + statusCode + ".", null)
      }
    }
  }

  FileView {
    id: connectionFile
    path: root.connectionPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      root.connection = Model.parseConnection(text())
      root.connectionLoaded = true
      root.migrateLegacyUrl()
      root.refreshHeader()
    }
    onLoadFailed: {
      root.connection = Model.emptyConnection()
      root.connectionLoaded = true
      root.headerReady = false
      root.migrateLegacyUrl()
      if (root.dirsReady && !root.configured) root.status = "unconfigured"
    }
    onFileChanged: reload()
  }

  // --- Lifecycle -----------------------------------------------------------
  Component.onCompleted: {
    ensureDirProc.command = Model.ensurePrivateDirsCmd(root.stateDir, root.cacheDir)
    ensureDirProc.running = true
  }

  onShellChanged: root.loadSettings()

  Connections {
    target: root.shell
    ignoreUnknownSignals: true
    function onBarConfigChanged() { root.loadSettings() }
    function onShellConfigChanged() { root.loadSettings() }
  }

  onBaseUrlChanged: {
    if (root.configured && root.headerReady) root.forcePoll()
  }

  onPanelOpenChanged: if (root.panelOpen) root.forcePoll()

  Timer {
    interval: Math.max(Model.MIN_POLL_SECONDS, root.pollSeconds) * 1000
    running: root.configured && root.headerReady
    repeat: true
    onTriggered: root.forcePoll()
  }
}
