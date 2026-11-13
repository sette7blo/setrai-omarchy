import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "qml"
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "io.github.sette7blo.setrai"

  readonly property string pluginDir: (Quickshell.env("HOME") || "") + "/.config/omarchy/plugins/io.github.sette7blo.setrai"

  // Service.qml instance, provided by Omarchy's plugin host.
  readonly property var service: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null

  readonly property bool configured: service ? service.configured === true : false
  readonly property var openWorkout: service ? service.openWorkout : null
  readonly property bool hasResume: !!openWorkout
  readonly property var readiness: service ? service.readiness : null

  readonly property color foreground: bar ? bar.barForeground : Commons.Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)

  // Colour has one meaning in the bar: a workout is open. Readiness is read
  // from the tooltip and the popup instead.
  readonly property color iconColor: !configured ? dim
    : (hasResume ? button.activeColor : foreground)

  readonly property string statusTooltip: {
    if (!configured) return "Setrai is not set up"
    if (hasResume) return openWorkout.programName
      ? "Workout in progress: " + openWorkout.programName
      : "Workout in progress"
    if (readiness !== null && readiness !== undefined)
      return "Readiness " + Model.formatReadinessPct(readiness)
    return "Setrai"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("service" in target) target.service = root.service
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  onBarChanged: injectPanel()
  onServiceChanged: injectPanel()

  // Panel contract for the bar's popout coordinator. The open state is shown
  // by the bar's own underline, not by the widget.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }
  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }
  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }
  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.hasResume
    tooltipText: root.statusTooltip
    iconComponent: Component {
      DumbbellIcon {
        size: Style.bar.iconCanvas
        iconColor: root.iconColor
        strokeWidth: 2.4

        Behavior on iconColor {
          enabled: !root.bar || root.bar.foregroundAnimationEnabled
          ColorAnimation { duration: Style.duration(160) }
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) {
        root.togglePanel()
      } else if (buttonCode === Qt.RightButton) {
        if (root.bar) root.bar.run("xdg-open " + root.pluginDir + "/README.md")
      }
    }
  }
}
