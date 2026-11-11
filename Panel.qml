import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "qml"

Panel {
  id: root
  moduleName: "io.github.sette7blo.setrai"
  ipcTarget: "io.github.sette7blo.setrai"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var snapshot: hostWidget ? hostWidget.snapshot : null

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color background: bar ? bar.background : Color.background
  readonly property color accent: bar ? bar.accent : Color.accent
  readonly property color dim: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.58)

  // Theme reader provides semantic traffic-light colors + extra palette slots
  // (bgAlt / fgDim) not exposed by the bar primitives. Fully reactive on
  // theme switch — no restart required.
  ThemeColors { id: themeColors }
  readonly property color readyColor: themeColors.readyColor
  readonly property color midColor: themeColors.midColor
  readonly property color lowColor: themeColors.lowColor

  // Keep opened in sync with hostWidget so clicks on the bar toggle correctly.
  readonly property bool opened: controller && controller.opened

  function formatKg(value, suffix) {
    if (value === null || value === undefined) return "—"
    var n = Number(value)
    if (!isFinite(n)) return "—"
    return n.toFixed(1) + (suffix || " kg")
  }

  function formatReadiness(value) {
    if (value === null || value === undefined) return "—"
    return Math.round(Number(value) * 100) + "%"
  }

  function readinessColor(value) {
    return themeColors.colorFor(value)
  }

  function formatRelative(iso) {
    if (!iso) return "—"
    var when = new Date(iso)
    var now = new Date()
    var minutes = Math.round((now - when) / 60000)
    if (minutes < 60) return minutes + "m ago"
    var hours = Math.round(minutes / 60)
    if (hours < 24) return hours + "h ago"
    var days = Math.round(hours / 24)
    return days + "d ago"
  }

  function openSetrai() {
    if (!root.bar) return
    root.bar.run("xdg-open " + ((root.hostWidget && root.hostWidget.pluginDir)
      ? root.hostWidget.pluginDir + "/bin/setrai-open.sh"
      : "http://localhost:3000"))
  }

  function open() { if (controller) controller.show() }
  function close() { if (controller) controller.hide() }
  function toggle() { if (controller) controller.toggle() }

  anchor.item: anchorItem
  anchor.rect.width: anchorItem ? anchorItem.width : 0
  anchor.rect.height: anchorItem ? anchorItem.height : 0

  implicitWidth: Style.space(220)
  implicitHeight: content.implicitHeight + Style.space(24)

  Rectangle {
    anchors.fill: parent
    color: root.background
    radius: Style.radius
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

    ColumnLayout {
      id: content
      anchors.fill: parent
      anchors.margins: Style.space(12)
      spacing: Style.space(10)

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: qsTr("Setrai")
          color: root.foreground
          font.pixelSize: Style.font.sizeMedium
          font.weight: Font.Bold
        }
        Item { Layout.fillWidth: true }
        Text {
          text: root.snapshot && root.snapshot.activeProgram
            ? root.snapshot.activeProgram.name
            : qsTr("No active program")
          color: root.dim
          font.pixelSize: Style.font.sizeSmall
          elide: Text.ElideRight
          Layout.maximumWidth: Style.space(120)
        }
      }

      // Resume banner (only when a session is open)
      Rectangle {
        Layout.fillWidth: true
        visible: root.snapshot && root.snapshot.resumeWorkout
        implicitHeight: resumeRow.implicitHeight + Style.space(12)
        radius: Style.radius / 2
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)

        RowLayout {
          id: resumeRow
          anchors.fill: parent
          anchors.margins: Style.space(8)
          spacing: Style.space(8)

          Text {
            text: "▶"
            color: root.accent
            font.pixelSize: Style.font.sizeMedium
          }
          Text {
            text: qsTr("Resume workout")
            color: root.foreground
            font.pixelSize: Style.font.sizeSmall
            Layout.fillWidth: true
          }
          MouseArea {
            anchors.fill: parent
            onClicked: root.openSetrai()
            cursorShape: Qt.PointingHandCursor
          }
        }
      }

      // Today stat
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: qsTr("Today")
          color: root.dim
          font.pixelSize: Style.font.sizeSmall
          Layout.preferredWidth: Style.space(70)
        }
        Text {
          text: root.formatKg(root.snapshot && root.snapshot.today ? root.snapshot.today.volumeKg : null)
          color: root.foreground
          font.pixelSize: Style.font.sizeSmall
          Layout.fillWidth: true
        }
        Text {
          text: (root.snapshot && root.snapshot.today ? root.snapshot.today.sessionsCompleted : 0) + "× "
          color: root.dim
          font.pixelSize: Style.font.sizeSmall
        }
      }

      // Week stat
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: qsTr("Week")
          color: root.dim
          font.pixelSize: Style.font.sizeSmall
          Layout.preferredWidth: Style.space(70)
        }
        Text {
          text: root.formatKg(root.snapshot && root.snapshot.week ? root.snapshot.week.volumeKg : null)
          color: root.foreground
          font.pixelSize: Style.font.sizeSmall
          Layout.fillWidth: true
        }
        Text {
          text: (root.snapshot && root.snapshot.week ? root.snapshot.week.sessions : 0) + "× "
          color: root.dim
          font.pixelSize: Style.font.sizeSmall
        }
      }

      // Readiness bar
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(4)
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: qsTr("Readiness")
            color: root.dim
            font.pixelSize: Style.font.sizeSmall
          }
          Item { Layout.fillWidth: true }
          Text {
            text: root.formatReadiness(root.snapshot && root.snapshot.week ? root.snapshot.week.readiness : null)
            color: root.readinessColor(root.snapshot && root.snapshot.week ? root.snapshot.week.readiness : null)
            font.pixelSize: Style.font.sizeSmall
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
          text: qsTr("Last")
          color: root.dim
          font.pixelSize: Style.font.sizeSmall
          Layout.preferredWidth: Style.space(70)
        }
        Text {
          text: root.snapshot && root.snapshot.lastWorkout
            ? (root.snapshot.lastWorkout.name || qsTr("workout")) +
              " · " + root.formatRelative(root.snapshot.lastWorkout.finishedAt)
            : "—"
          color: root.foreground
          font.pixelSize: Style.font.sizeSmall
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
      }

      // Body weight
      RowLayout {
        Layout.fillWidth: true
        visible: root.snapshot && root.snapshot.body
        Text {
          text: qsTr("Body")
          color: root.dim
          font.pixelSize: Style.font.sizeSmall
          Layout.preferredWidth: Style.space(70)
        }
        Text {
          text: root.snapshot && root.snapshot.body
            ? root.formatKg(root.snapshot.body.weightKg)
            : "—"
          color: root.foreground
          font.pixelSize: Style.font.sizeSmall
          Layout.fillWidth: true
        }
      }

      // Open button
      Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Style.space(4)
        implicitHeight: openLabel.implicitHeight + Style.space(10)
        radius: Style.radius / 2
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
        border.width: 1
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

        Text {
          id: openLabel
          anchors.centerIn: parent
          text: qsTr("Open Setrai")
          color: root.foreground
          font.pixelSize: Style.font.sizeSmall
          font.weight: Font.Medium
        }
        MouseArea {
          anchors.fill: parent
          onClicked: root.openSetrai()
          cursorShape: Qt.PointingHandCursor
        }
      }
    }
  }

  // Idle state when no snapshot has ever loaded.
  Text {
    anchors.centerIn: parent
    visible: !root.snapshot
    text: qsTr("Setrai is idle. Enable snapshot in .env.")
    color: root.dim
    font.pixelSize: Style.font.sizeSmall
  }
}
