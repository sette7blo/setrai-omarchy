import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Connection settings shown in place of the panel body. The panel header
// owns the title and the close control, so this view is fields and actions
// only.
Column {
  id: root

  property var service: null
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property bool editorOpen: urlField.activeFocus || keyField.activeFocus || pollField.field.activeFocus

  property string probeMessage: ""
  property bool probeOk: false
  property bool probing: false
  property bool edited: false
  property bool dirty: Model.normalizeBaseUrl(urlField.text) !== (service ? service.baseUrl : "")
    || keyField.text !== (service ? service.apiKey : "")
    || pollField.value !== (service ? service.pollSeconds : Model.DEFAULT_POLL_SECONDS)

  signal closeSettings()

  function reset() {
    if (!service) return
    urlField.text = service.baseUrl || Model.DEFAULT_BASE_URL
    keyField.text = service.apiKey || ""
    pollField.value = service.pollSeconds || Model.DEFAULT_POLL_SECONDS
    probeMessage = ""
    probeOk = false
    probing = false
    edited = false
  }

  function save() {
    if (!service) return
    service.persistSettings({ pollSeconds: pollField.value })
    service.persistConnection({ baseUrl: urlField.text, apiKey: keyField.text })
  }

  Component.onCompleted: reset()

  Connections {
    target: root.service
    ignoreUnknownSignals: true
    // Saved values can arrive after the view opens; follow them until the
    // user starts editing.
    function onApiKeyChanged() { if (!root.edited) root.reset() }
    function onBaseUrlChanged() { if (!root.edited) root.reset() }
    function onPollSecondsChanged() { if (!root.edited) root.reset() }
    function onConnectionProbed(ok, message, info) {
      root.probing = false
      root.probeOk = ok
      root.probeMessage = String(message || "")
    }
  }

  width: parent ? parent.width : implicitWidth
  spacing: Style.spacing.xxl

  component FieldLabel: Text {
    textFormat: Text.PlainText
    font.pixelSize: Style.font.bodySmall
  }

  // ---- Server ----
  Column {
    width: parent.width
    spacing: Style.spacing.md

    FieldLabel {
      text: "Server address"
      color: root.dim
      font.family: root.fontFamily
    }
    TextField {
      id: urlField
      width: parent.width
      placeholderText: Model.DEFAULT_BASE_URL
      foreground: root.foreground
      accent: root.accent
      onTextEdited: { root.edited = true; root.probeMessage = "" }
    }
  }

  // ---- API key ----
  Column {
    width: parent.width
    spacing: Style.spacing.md

    FieldLabel {
      text: "API key"
      color: root.dim
      font.family: root.fontFamily
    }
    TextField {
      id: keyField
      width: parent.width
      placeholderText: "setrai_..."
      password: true
      foreground: root.foreground
      accent: root.accent
      onTextEdited: { root.edited = true; root.probeMessage = "" }
    }
    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: "Create one in Setrai under Settings, API keys. It is shown only once."
      color: root.dim
      wrapMode: Text.WordWrap
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  // ---- Refresh ----
  NumberField {
    id: pollField
    width: parent.width
    label: "Refresh every (seconds)"
    value: root.service ? root.service.pollSeconds : Model.DEFAULT_POLL_SECONDS
    from: Model.MIN_POLL_SECONDS
    to: Model.MAX_POLL_SECONDS
    stepSize: 5
    foreground: root.foreground
    accent: root.accent
    fontFamily: root.fontFamily
    onModified: function(v) { root.edited = true; pollField.value = v }
  }

  PanelSeparator { foreground: root.foreground }

  // ---- Connection result ----
  Row {
    width: parent.width
    spacing: Style.spacing.lg
    visible: root.probing || root.probeMessage !== ""

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(6)
      height: width
      radius: width / 2
      color: root.probing ? root.dim : (root.probeOk ? root.foreground : Color.urgent)
    }
    Text {
      textFormat: Text.PlainText
      width: parent.width - Style.space(6) - parent.spacing
      text: root.probing ? "Testing connection" : root.probeMessage
      color: root.probing ? root.dim : (root.probeOk ? root.foreground : Color.urgent)
      wrapMode: Text.WordWrap
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  // ---- Actions ----
  RowLayout {
    width: parent.width
    spacing: Style.spacing.lg

    Button {
      text: "Test connection"
      bordered: true
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      onClicked: {
        if (!root.service) return
        root.probing = true
        root.probeMessage = ""
        root.service.testConnection(urlField.text, keyField.text)
      }
    }

    Item { Layout.fillWidth: true }

    Button {
      text: "Save"
      bordered: true
      selected: root.dirty
      enabled: root.dirty
      opacity: root.dirty ? 1 : 0.45
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      onClicked: {
        root.save()
        root.closeSettings()
      }
    }
  }

  PanelSeparator { foreground: root.foreground }

  // ---- Coach ----
  Column {
    width: parent.width
    spacing: Style.spacing.lg

    PanelSectionHeader {
      text: "AI coach"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }
    Toggle {
      width: parent.width
      label: "Enable the coach"
      description: "Off unless you turn it on."
      checked: root.service ? root.service.coachEnabled : false
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      onClicked: {
        if (!root.service) return
        root.service.persistSettings({ coach: !root.service.coachEnabled })
      }
    }
    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: "The coach adds an Ask coach button that opens your own default Omarchy agent (claude, codex, cursor-agent or copilot) in a terminal, with Setrai docked beside it, and points it at your training data. It opens with the agent's normal permission prompts, so it asks before running commands. The plugin has no AI of its own and no AI key, and sends nothing anywhere itself. What the agent sends to its provider is between you and that agent."
      color: root.dim
      wrapMode: Text.WordWrap
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
    // Pre-approvals: the coach starts with exactly these Setrai commands
    // allowed, for that session only. Everything else still asks.
    Toggle {
      width: parent.width
      visible: !!root.service && root.service.coachEnabled
      label: "Read Setrai without asking"
      description: "Stats, sessions, programs, recovery and your profile."
      checked: root.service ? root.service.coachRead : false
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      onClicked: if (root.service) root.service.persistSettings({ coachRead: !root.service.coachRead })
    }
    Toggle {
      width: parent.width
      visible: !!root.service && root.service.coachEnabled
      label: "Change Setrai without asking"
      description: "Saving or changing programs, starting workouts, logging weight. A program the coach designs is still shown before it is saved."
      checked: root.service ? root.service.coachWrite : false
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      onClicked: if (root.service) root.service.persistSettings({ coachWrite: !root.service.coachWrite })
    }
    Text {
      textFormat: Text.PlainText
      width: parent.width
      visible: !!root.service && root.service.coachEnabled && (root.service.coachRead || root.service.coachWrite)
      text: root.service && root.service.agentName === "codex"
        ? "Codex has no per-command approval, so it still asks every time."
        : "Only the plugin's own Setrai commands are allowed, for the coach's session only. Anything else the agent wants to run still asks. Applies the next time you ask the coach."
      color: root.dim
      wrapMode: Text.WordWrap
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
    Text {
      textFormat: Text.PlainText
      width: parent.width
      visible: !!root.service && root.service.coachEnabled && !root.service.agentReady && root.service.agentNote !== ""
      text: root.service ? root.service.agentNote : ""
      color: Color.urgent
      wrapMode: Text.WordWrap
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}
