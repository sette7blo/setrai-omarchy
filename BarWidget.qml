import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "qml"

BarWidget {
  id: root
  moduleName: "io.github.sette7blo.setrai"

  readonly property string pluginDir: (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/io.github.sette7blo.setrai"
  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")
  readonly property string snapshotPath: dataHome + "/setrai/snapshot.json"

  property var snapshot: null
  readonly property bool hasResume: snapshot && snapshot.resumeWorkout
  readonly property real todayVolume: snapshot && snapshot.today ? Number(snapshot.today.volumeKg || 0) : 0

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color accent: Commons.Color.accent
  readonly property color dim: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.58)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  implicitWidth: pill.implicitWidth
  implicitHeight: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal

  function formatVolume(kg) {
    if (!(kg > 0)) return "idle"
    if (kg >= 1000) return (kg / 1000).toFixed(1) + "t"
    return Math.round(kg) + "kg"
  }

  function loadSnapshot(payload) {
    try {
      var parsed = JSON.parse(String(payload || "{}"))
      if (Number(parsed.schemaVersion || 0) !== 1) {
        snapshot = null
        return
      }
      snapshot = parsed
    } catch (error) {
      snapshot = null
    }
  }

  function reload() { snapshotFile.reload() }

  // Shape contract the bar's popout coordinator and KeyboardPanel reach up
  // through: KeyboardPanel.close() calls owner.close() on outside-click, so
  // without these the bar's panelController.open stays stuck on `true` and
  // the next pill click toggles it closed from an already-hidden state.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property real openPanelIndicatorWidth: pill.width
  readonly property real openPanelIndicatorHeight: Style.space(2)

  function open() {
    if (panelLoader.item) { reload(); panelLoader.item.open() }
  }
  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }
  function togglePanel() {
    if (panelLoader.item) { reload(); panelLoader.item.toggle() }
  }
  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  FileView {
    id: snapshotFile
    path: root.snapshotPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loadSnapshot(text())
    onLoadFailed: root.snapshot = null
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      if (item) {
        item.bar = root.bar
        item.anchorItem = pill
        item.hostWidget = root
      }
    }
  }

  Rectangle {
    id: pill
    implicitWidth: layout.implicitWidth + Style.space(16)
    implicitHeight: Style.space(20)
    anchors.verticalCenter: parent.verticalCenter
    radius: height / 2
    color: root.opened
      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
      : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

    RowLayout {
      id: layout
      anchors.centerIn: parent
      spacing: Style.space(4)

      Item {
        readonly property real iconSize: Style.font.caption * 1.2
        implicitWidth: iconSize
        implicitHeight: iconSize

        Text {
          anchors.centerIn: parent
          visible: root.hasResume
          text: "▶"
          color: root.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        DumbbellIcon {
          anchors.centerIn: parent
          visible: !root.hasResume
          size: parent.iconSize
          iconColor: root.foreground
          strokeWidth: 2.4
        }
      }

      Text {
        text: root.hasResume ? "Resume" : root.formatVolume(root.todayVolume)
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.weight: Font.Medium
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
          root.togglePanel()
        } else if (mouse.button === Qt.RightButton) {
          if (root.bar) root.bar.run("xdg-open " + root.pluginDir + "/README.md")
        }
      }
    }
  }
}
