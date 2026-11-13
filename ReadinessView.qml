import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Readiness block: Setrai's overall readiness figure as the server reports
// it, with a caption and an optional detail line underneath.
RowLayout {
  id: root

  property var readiness: null
  property string detail: ""
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property string fontFamily: Style.font.family
  property real labelWidth: Style.space(76)

  width: parent ? parent.width : implicitWidth
  spacing: Style.spacing.xxl

  Text {
    textFormat: Text.PlainText
    Layout.preferredWidth: root.labelWidth
    Layout.alignment: Qt.AlignVCenter
    text: Model.formatReadinessPct(root.readiness)
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.display
    font.bold: true
  }

  Column {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
    spacing: Style.spacing.xxs

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: "Readiness"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
    }
    Text {
      textFormat: Text.PlainText
      width: parent.width
      visible: root.detail !== ""
      text: root.detail
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }
  }
}
