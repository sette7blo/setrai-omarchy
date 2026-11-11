import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.sette7blo.setrai"

  readonly property string pluginDir: (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/io.github.sette7blo.setrai"
  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")
  readonly property string snapshotPath: dataHome + "/setrai/snapshot.json"

  property var snapshot: null
  property bool popoverVisible: false
  readonly property bool hasResume: snapshot && snapshot.resumeWorkout
  readonly property real todayVolume: snapshot && snapshot.today ? Number(snapshot.today.volumeKg || 0) : 0
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: bar ? bar.accent : Color.accent
  readonly property color dim: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.58)

  implicitWidth: pill.implicitWidth
  implicitHeight: root.bar ? root.bar.barSize : Style.space(26)

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

  function reload() {
    snapshotFile.reload()
  }

  FileView {
    id: snapshotFile
    path: root.snapshotPath
    watchChanges: true
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
    color: root.popoverVisible
      ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
      : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

    RowLayout {
      id: layout
      anchors.centerIn: parent
      spacing: Style.space(4)

      Text {
        text: root.hasResume ? "▶" : "⚡"
        color: root.hasResume ? root.accent : root.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.sizeSmall
      }

      Text {
        text: root.hasResume ? qsTr("Resume") : root.formatVolume(root.todayVolume)
        color: root.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.sizeSmall
        font.weight: Font.Medium
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.LeftButton) {
          var panel = panelLoader.item
          if (!panel) return
          root.popoverVisible = !root.popoverVisible
          if (root.popoverVisible) {
            root.reload()
            if (panel.open) panel.open()
          } else {
            if (panel.close) panel.close()
          }
        } else if (mouse.button === Qt.RightButton) {
          if (root.bar) root.bar.run("xdg-open " + root.pluginDir + "/README.md")
        }
      }
    }
  }
}
