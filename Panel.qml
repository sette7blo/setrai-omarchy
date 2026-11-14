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

  readonly property var barIdentity: hostWidget || root

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property real labelWidth: Style.space(76)

  readonly property bool configured: service ? service.configured === true : false
  readonly property var openWorkout: service ? service.openWorkout : null
  readonly property bool hasResume: !!openWorkout
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
      if (!root.opened) root.showSettings = false
    }
  }

  function openSetrai(path) {
    if (!bar || !root.hostWidget) return
    bar.run(root.hostWidget.pluginDir + "/bin/setrai-open.sh " + (path || "/"))
    close()
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
            onClicked: root.showSettings = !root.showSettings
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

      // ---- Readiness ----
      ReadinessView {
        visible: !root.showSettings && root.hasReadiness
        readiness: root.service ? root.service.readiness : null
        detail: root.lastWorkoutText
        foreground: root.foreground
        dim: root.dim
        fontFamily: root.fontFamily
        labelWidth: root.labelWidth
      }

      PanelSeparator {
        foreground: root.foreground
        visible: !root.showSettings && root.hasReadiness
      }

      // ---- Training ----
      Column {
        width: parent.width
        spacing: Style.spacing.md
        visible: !root.showSettings && root.configured

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
        visible: !root.showSettings && root.configured
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
        visible: !root.showSettings && root.configured
      }

      // ---- Actions ----
      RowLayout {
        width: parent.width
        spacing: Style.spacing.lg
        visible: !root.showSettings && root.configured

        Button {
          Layout.fillWidth: true
          text: root.hasResume ? "Resume workout" : "Open Setrai"
          bordered: true
          selected: root.hasResume
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: root.hasResume
            ? root.openSetrai(root.openWorkout.url)
            : root.openSetrai("/")
        }
        Button {
          visible: root.hasResume
          text: "Open Setrai"
          bordered: true
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: root.openSetrai("/")
        }
      }
    }
  }
}
