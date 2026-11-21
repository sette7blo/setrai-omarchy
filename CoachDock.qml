import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "qml"
import "Model.js" as Model

// Setrai docked on the left edge while the coach runs in a terminal. The
// exclusive zone reserves the strip the way the bar does, so Hyprland tiles
// the terminal into the rest of the screen. It only shows what the API
// returns; acting on it is the coach's job, or the popover's.
PanelWindow {
  id: root

  required property var service

  readonly property color foreground: Commons.Color.popups.text
  readonly property color accent: Commons.Color.accent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: Style.font.family
  readonly property real labelWidth: Style.space(76)
  // Hyprland keeps windows a full gaps_out from the edges; Style.gapsOut is half.
  readonly property real edgeGap: Style.gapsOut * 2
  readonly property real cardWidth: Style.space(340)

  readonly property bool configured: service.configured === true
  readonly property bool hasReadiness: configured && service.readiness !== null
  readonly property string weightUnit: service.weightUnit
  readonly property string notice: {
    if (!configured) return "Connect your Setrai server in the panel settings."
    if (service.status === "unauthorized") return "Setrai did not accept the API key."
    if (service.status === "unreachable") return "Setrai is not responding."
    if (service.status === "error") return service.statusDetail || "Setrai returned an error."
    return ""
  }

  screen: service.coachScreen
  visible: service.coachDockShown
  color: "transparent"

  WlrLayershell.namespace: "setrai-coach-dock"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: implicitWidth

  anchors {
    top: true
    bottom: true
    left: true
  }
  implicitWidth: edgeGap + cardWidth

  BorderSurface {
    id: card
    x: root.edgeGap
    y: root.edgeGap
    width: root.cardWidth
    height: parent.height - root.edgeGap * 2
    color: Commons.Color.popups.background
    borderSpec: Border.surfaceSpec("popups", "border", Commons.Color.popups.border, Math.max(1, Style.space(2)))
    padding: Style.spacing.popupPadding
    radius: Style.cornerRadius
    clip: true

    Flickable {
      id: flick
      anchors.fill: parent
      anchors.topMargin: card.contentTopInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.leftMargin: card.contentLeftInset
      anchors.rightMargin: card.contentRightInset
      contentWidth: width
      contentHeight: body.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      ScrollBar.vertical: ScrollBar {
        id: scroll
        policy: ScrollBar.AsNeeded
      }

      Column {
        id: body
        width: flick.width - (flick.interactive ? scroll.width + Style.space(6) : 0)
        spacing: Style.spacing.xxl

        PanelHero {
          width: parent.width
          title: "Setrai"
          meta: "Coach"
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
              iconText: "\u{f0156}"
              tooltipText: "Close coach"
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.service.closeCoach()
            }
          }
        }

        PanelSeparator { foreground: root.foreground }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          visible: root.notice !== ""
          text: root.notice
          color: root.foreground
          wrapMode: Text.WordWrap
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }

        // ---- Readiness ----
        ReadinessView {
          visible: root.hasReadiness
          readiness: root.service.readiness
          detail: {
            var when = Model.relativeDay(root.service.lastWorkoutAt)
            return when ? "Last workout " + when : ""
          }
          foreground: root.foreground
          dim: root.dim
          fontFamily: root.fontFamily
          labelWidth: root.labelWidth
        }

        PanelSeparator {
          foreground: root.foreground
          visible: root.hasReadiness
        }

        // ---- This week ----
        Column {
          width: parent.width
          spacing: Style.spacing.md
          visible: root.configured

          Repeater {
            model: {
              var svc = root.service
              var rows = [
                { label: "This week", value: Model.formatSessions(svc.sessionsThisWeek) },
                { label: "Volume", value: Model.formatVolume(svc.weekVolumeKg, root.weightUnit) }
              ]
              var streak = Model.formatStreak(svc.streak)
              if (streak) rows.push({ label: "Streak", value: streak })
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
          visible: root.configured
        }

        // ---- Body weight ----
        BodyChart {
          visible: root.configured
          allowEntry: false
          chartHeight: Style.space(64)
          entries: root.service.bodyEntries
          changeKg: root.service.bodyChangeKg
          unit: root.weightUnit
          service: root.service
          foreground: root.foreground
          dim: root.dim
          accent: root.accent
          fontFamily: root.fontFamily
        }

        PanelSeparator {
          foreground: root.foreground
          visible: root.configured
        }

        // ---- Recent sessions ----
        Column {
          width: parent.width
          spacing: Style.spacing.md
          visible: root.configured

          PanelSectionHeader {
            width: parent.width
            text: "Recent sessions"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Text {
            textFormat: Text.PlainText
            visible: root.service.recentSessions.length === 0
            text: "No finished sessions yet."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: root.service.recentSessions
            delegate: RowLayout {
              required property var modelData
              width: parent.width
              spacing: Style.spacing.xxl

              Text {
                textFormat: Text.PlainText
                Layout.preferredWidth: root.labelWidth
                text: Model.relativeDay(modelData.finishedAt)
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
              Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                text: modelData.programName
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
          visible: root.configured
        }

        // ---- Saved programs ----
        Column {
          width: parent.width
          spacing: Style.spacing.md
          visible: root.configured

          PanelSectionHeader {
            width: parent.width
            text: "Programs"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Text {
            textFormat: Text.PlainText
            visible: text !== ""
            text: !root.service.programsLoaded ? "Loading programs..."
              : (root.service.programs.length ? "" : "No saved programs yet.")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: root.service.programs
            delegate: Text {
              required property var modelData
              textFormat: Text.PlainText
              width: parent.width
              text: modelData.label
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
