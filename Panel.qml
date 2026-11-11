import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.sette7blo.setrai"
  ipcTarget: "io.github.sette7blo.setrai"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property var snapshot: hostWidget ? hostWidget.snapshot : null

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color background: bar ? bar.background : Commons.Color.background
  readonly property color accent: Commons.Color.accent
  readonly property color dim: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.58)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Semantic traffic-light stays theme-independent — readiness carries
  // meaning that should survive an accent swap.
  readonly property color readyColor: "#63d297"
  readonly property color midColor: "#e5c07b"
  readonly property color lowColor: "#ff6b7a"

  function formatKg(value) {
    if (value === null || value === undefined) return "—"
    var n = Number(value)
    if (!isFinite(n)) return "—"
    return n.toFixed(1) + " kg"
  }

  function formatReadiness(value) {
    if (value === null || value === undefined) return "—"
    return Math.round(Number(value) * 100) + "%"
  }

  function readinessColor(value) {
    if (value === null || value === undefined) return root.dim
    var v = Number(value)
    if (v >= 0.75) return root.readyColor
    if (v >= 0.5) return root.midColor
    return root.lowColor
  }

  function formatRelative(iso) {
    if (!iso) return "—"
    var when = new Date(iso)
    var minutes = Math.round((new Date() - when) / 60000)
    if (minutes < 60) return minutes + "m ago"
    var hours = Math.round(minutes / 60)
    if (hours < 24) return hours + "h ago"
    return Math.round(hours / 24) + "d ago"
  }

  function openSetrai(path) {
    if (!bar) return
    bar.run(root.hostWidget.pluginDir + "/bin/setrai-open.sh " + (path || "/"))
    close()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(280))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(420))

    ColumnLayout {
      id: content
      anchors.fill: parent
      anchors.margins: Style.space(12)
      spacing: Style.space(10)

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Setrai"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }
        Item { Layout.fillWidth: true }
        Text {
          text: root.snapshot && root.snapshot.activeProgram
            ? root.snapshot.activeProgram.name
            : "No active program"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          Layout.maximumWidth: Style.space(140)
        }
      }

      // Resume banner (only when a session is open)
      Rectangle {
        Layout.fillWidth: true
        visible: root.snapshot && root.snapshot.resumeWorkout
        implicitHeight: resumeRow.implicitHeight + Style.space(12)
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : Style.space(4)
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)

        RowLayout {
          id: resumeRow
          anchors.fill: parent
          anchors.margins: Style.space(8)
          spacing: Style.space(8)

          Text {
            text: "▶"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
          Text {
            text: "Resume workout"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            Layout.fillWidth: true
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.openSetrai(root.snapshot.resumeWorkout.url)
        }
      }

      // Today / Week stat rows
      Repeater {
        model: [
          {
            label: "Today",
            volume: root.snapshot && root.snapshot.today ? root.snapshot.today.volumeKg : null,
            count:  root.snapshot && root.snapshot.today ? root.snapshot.today.sessionsCompleted : 0
          },
          {
            label: "Week",
            volume: root.snapshot && root.snapshot.week ? root.snapshot.week.volumeKg : null,
            count:  root.snapshot && root.snapshot.week ? root.snapshot.week.sessions : 0
          }
        ]
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: modelData.label
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            Layout.preferredWidth: Style.space(70)
          }
          Text {
            text: root.formatKg(modelData.volume)
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            Layout.fillWidth: true
          }
          Text {
            text: modelData.count + "×"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }

      // Readiness bar
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Readiness"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
          Item { Layout.fillWidth: true }
          Text {
            text: root.formatReadiness(root.snapshot && root.snapshot.week ? root.snapshot.week.readiness : null)
            color: root.readinessColor(root.snapshot && root.snapshot.week ? root.snapshot.week.readiness : null)
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.weight: Font.Medium
          }
        }
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 4
          radius: 2
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1,
              root.snapshot && root.snapshot.week ? Number(root.snapshot.week.readiness || 0) : 0))
            radius: parent.radius
            color: root.readinessColor(root.snapshot && root.snapshot.week ? root.snapshot.week.readiness : null)
            Behavior on width { NumberAnimation { duration: 240 } }
          }
        }
      }

      // Last workout
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Last"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          Layout.preferredWidth: Style.space(70)
        }
        Text {
          text: root.snapshot && root.snapshot.lastWorkout
            ? (root.snapshot.lastWorkout.name || "workout") + " · " + root.formatRelative(root.snapshot.lastWorkout.finishedAt)
            : "—"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
      }

      // Body weight
      RowLayout {
        Layout.fillWidth: true
        visible: root.snapshot && root.snapshot.body
        Text {
          text: "Body"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          Layout.preferredWidth: Style.space(70)
        }
        Text {
          text: root.snapshot && root.snapshot.body ? root.formatKg(root.snapshot.body.weightKg) : "—"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          Layout.fillWidth: true
        }
      }

      // Idle hint when no snapshot has ever loaded
      Text {
        Layout.fillWidth: true
        visible: !root.snapshot
        text: "Setrai is idle. Enable snapshot in .env."
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
      }

      // Open Setrai button
      Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Style.space(4)
        implicitHeight: openLabel.implicitHeight + Style.space(10)
        radius: Style.cornerRadius > 0 ? Style.cornerRadius : Style.space(4)
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

        Text {
          id: openLabel
          anchors.centerIn: parent
          text: "Open Setrai"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.weight: Font.Medium
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.openSetrai("/")
        }
      }
    }
  }
}
