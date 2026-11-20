import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "qml"
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.sette7blo.setrai"
  ipcTarget: "io.github.sette7blo.setrai"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null
  property bool showSettings: false
  // The program list that "Start workout" opens in place of the main view.
  property bool showPrograms: false
  readonly property bool showMain: !showSettings && !showPrograms

  readonly property var barIdentity: hostWidget || root

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property real labelWidth: Style.space(76)

  readonly property bool configured: service ? service.configured === true : false
  readonly property var openWorkout: service ? service.openWorkout : null
  readonly property bool hasResume: !!openWorkout
  readonly property bool coachOn: service ? service.coachEnabled && service.agentReady === true : false
  readonly property bool hasReadiness: configured && !!service && service.readiness !== null
  readonly property string weightUnit: service ? service.weightUnit : "kg"
  // True while a text field has focus, so the panel leaves the keys to it.
  readonly property bool settingsBlocked: (settingsLoader.item ? settingsLoader.item.editorOpen === true : false)
    || bodyChart.editorOpen

  readonly property string notice: {
    if (!service) return ""
    if (!configured) return "Connect your Setrai server to see training here."
    if (service.status === "unauthorized") return "Setrai did not accept the API key. Paste a new one in settings."
    if (service.status === "unreachable") return "Setrai is not responding. Check that the server is running."
    if (service.status === "error") return service.statusDetail || "Setrai returned an error."
    return ""
  }

  readonly property string heroMeta: {
    if (showSettings) return "Settings"
    if (showPrograms) return "Choose a program"
    if (!configured) return "Not connected"
    if (hasResume) return openWorkout.programName
      ? "Workout in progress: " + openWorkout.programName
      : "Workout in progress"
    return ""
  }

  readonly property string lastWorkoutText: {
    var when = service ? Model.relativeDay(service.lastWorkoutAt) : ""
    return when ? "Last workout " + when : ""
  }

  Connections {
    target: root
    function onOpenedChanged() {
      if (root.service) root.service.panelOpen = root.opened
      if (!root.opened) {
        root.showSettings = false
        root.showPrograms = false
      }
    }
  }

  function openSetrai(path) {
    if (!bar || !root.hostWidget) return
    bar.run(root.hostWidget.pluginDir + "/bin/setrai-open.sh " + (path || "/"))
    close()
  }

  function chooseProgram() {
    if (root.service) root.service.loadPrograms()
    root.showPrograms = true
  }

  // The CLI starts the session and opens it; if a workout is already in
  // progress it opens that one instead.
  function startProgram(id) {
    var programId = Math.floor(Number(id))
    if (!bar || !root.hostWidget || !(programId > 0)) return
    bar.run(root.hostWidget.pluginDir + "/bin/setrai start " + programId)
    close()
  }

  // Docks Setrai on the left and opens the default Omarchy agent beside it;
  // the CLI reports if no agent is set.
  function askCoach() {
    if (!root.coachOn) return
    close()
    root.service.startCoach()
  }

  Component {
    id: settingsComp
    SettingsView {
      width: body.width
      service: root.service
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      onCloseSettings: root.showSettings = false
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(body.implicitHeight, Style.space(640))

    PanelKeyCatcher {
      anchors.fill: parent
      blocked: root.settingsBlocked
      onCloseRequested: root.close()
    }

    // KeyboardPanel already pads its content; the column only sizes itself
    // so implicitHeight matches what is drawn and nothing gets clipped.
    Column {
      id: body
      width: parent.width
      spacing: Style.spacing.xxl

      PanelHero {
        title: "Setrai"
        meta: root.heroMeta
        foreground: root.foreground
        fontFamily: root.fontFamily
        iconComponent: Component {
          DumbbellIcon {
            size: Style.font.display
            iconColor: root.foreground
            strokeWidth: 1.75
          }
        }
        trailingControl: Component {
          PanelActionButton {
            iconText: root.showSettings ? "\u{f0156}" : "\u{f0493}"
            tooltipText: root.showSettings ? "Close settings" : "Settings"
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: {
              root.showPrograms = false
              root.showSettings = !root.showSettings
            }
          }
        }
      }

      PanelSeparator { foreground: root.foreground }

      Loader {
        id: settingsLoader
        width: parent.width
        active: root.showSettings
        visible: active
        sourceComponent: settingsComp
      }

      // ---- Connection notice ----
      Column {
        width: parent.width
        spacing: Style.spacing.lg
        visible: !root.showSettings && root.notice !== ""

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: root.notice
          color: root.foreground
          wrapMode: Text.WordWrap
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }
        Button {
          text: root.configured ? "Open settings" : "Connect"
          bordered: true
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: root.showSettings = true
        }
      }

      // ---- Program picker ----
      Column {
        width: parent.width
        spacing: Style.spacing.md
        visible: root.showPrograms && !root.showSettings

        Text {
          textFormat: Text.PlainText
          width: parent.width
          visible: text !== ""
          text: {
            var svc = root.service
            if (!svc || root.notice !== "") return ""
            if (!svc.programsLoaded) return "Loading programs..."
            return svc.programs.length ? "" : "No saved programs. Create one in Setrai first."
          }
          color: root.dim
          wrapMode: Text.WordWrap
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }

        Flickable {
          id: programFlick
          width: parent.width
          height: Math.min(programColumn.implicitHeight, Style.space(320))
          visible: programRepeater.count > 0
          contentWidth: width
          contentHeight: programColumn.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          interactive: contentHeight > height
          ScrollBar.vertical: ScrollBar {
            id: programScroll
            policy: ScrollBar.AsNeeded
          }

          Column {
            id: programColumn
            width: programFlick.width - (programFlick.interactive ? programScroll.width + Style.space(6) : 0)
            spacing: Style.spacing.sm

            Repeater {
              id: programRepeater
              model: root.service ? root.service.programs : []
              delegate: Button {
                required property var modelData
                width: programColumn.width
                leftAlign: true
                text: modelData.label
                foreground: root.foreground
                accent: root.accent
                fontFamily: root.fontFamily
                onClicked: root.startProgram(modelData.id)
              }
            }
          }
        }

        Button {
          text: "Back"
          bordered: true
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: root.showPrograms = false
        }
      }

      // ---- Readiness ----
      ReadinessView {
        visible: root.showMain && root.hasReadiness
        readiness: root.service ? root.service.readiness : null
        detail: root.lastWorkoutText
        foreground: root.foreground
        dim: root.dim
        fontFamily: root.fontFamily
        labelWidth: root.labelWidth
      }

      PanelSeparator {
        foreground: root.foreground
        visible: root.showMain && root.hasReadiness
      }

      // ---- Training ----
      Column {
        width: parent.width
        spacing: Style.spacing.md
        visible: root.showMain && root.configured

        Repeater {
          model: {
            var svc = root.service
            var rows = [
              { label: "This week", value: Model.formatSessions(svc ? svc.sessionsThisWeek : 0) },
              { label: "Volume", value: Model.formatVolume(svc ? svc.weekVolumeKg : 0, root.weightUnit) }
            ]
            if (!root.hasReadiness && root.lastWorkoutText !== "")
              rows.push({ label: "Last", value: root.lastWorkoutText })
            return rows
          }
          delegate: RowLayout {
            required property var modelData
            width: parent.width
            spacing: Style.spacing.xxl

            Text {
              textFormat: Text.PlainText
              Layout.preferredWidth: root.labelWidth
              text: modelData.label
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
            Text {
              textFormat: Text.PlainText
              Layout.fillWidth: true
              text: modelData.value
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }
          }
        }
      }

      PanelSeparator {
        foreground: root.foreground
        visible: bodyChart.visible
      }

      // ---- Body weight ----
      // Shown without any entries too, so the first one can be logged here.
      BodyChart {
        id: bodyChart
        visible: root.showMain && root.configured
        entries: root.service ? root.service.bodyEntries : []
        changeKg: root.service ? root.service.bodyChangeKg : null
        unit: root.weightUnit
        service: root.service
        foreground: root.foreground
        dim: root.dim
        accent: root.accent
        fontFamily: root.fontFamily
      }

      PanelSeparator {
        foreground: root.foreground
        visible: root.showMain && root.configured
      }

      // ---- Actions ----
      RowLayout {
        width: parent.width
        spacing: Style.spacing.lg
        visible: root.showMain && root.configured

        Button {
          Layout.fillWidth: true
          text: root.hasResume ? "Resume workout" : "Start workout"
          bordered: true
          selected: root.hasResume
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: root.hasResume
            ? root.openSetrai(root.openWorkout.url)
            : root.chooseProgram()
        }
        Button {
          Layout.fillWidth: !root.hasResume
          text: "Open Setrai"
          bordered: true
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: root.openSetrai("/")
        }
        Button {
          visible: root.coachOn
          text: "Ask coach"
          bordered: true
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: root.askCoach()
        }
      }
    }
  }
}
