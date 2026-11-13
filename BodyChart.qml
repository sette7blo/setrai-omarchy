import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Body-weight block: section label, the latest weight with Setrai's total
// change (bodyWeightChangeKg), and a hairline trend over the full history.
// Weight direction is not good or bad on its own, so the change stays neutral.
Column {
  id: root

  property var entries: []                      // oldest -> newest, [{date, weightKg}]
  property var changeKg: null                   // latest minus first, from the server
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  readonly property var _latest: Model.latestBodyEntry(entries)
  readonly property string deltaText: {
    var t = Model.formatChangeKg(changeKg)
    if (!t || entries.length < 2) return ""
    return t === "No change" ? "No change in total" : t + " total"
  }

  spacing: Style.spacing.lg
  width: parent ? parent.width : implicitWidth

  PanelSectionHeader {
    width: parent.width
    text: "Body weight"
    foreground: root.foreground
    fontFamily: root.fontFamily
  }

  // ---- Latest weight + change ----
  Row {
    spacing: Style.spacing.lg
    visible: !!root._latest

    Text {
      id: weightText
      textFormat: Text.PlainText
      text: root._latest ? root._latest.weightKg.toFixed(1) + " kg" : ""
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.bold: true
    }
    Text {
      textFormat: Text.PlainText
      anchors.baseline: weightText.baseline
      text: root.deltaText
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  // ---- Trend line ----
  Item {
    width: parent.width
    height: Style.space(40)

    Canvas {
      id: chart
      anchors.fill: parent
      antialiasing: true
      visible: root.entries.length >= 2

      readonly property var pts: root.entries
      readonly property real pad: Style.space(4)

      onPtsChanged: requestPaint()
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
      onVisibleChanged: if (visible) requestPaint()

      Connections {
        target: root
        function onForegroundChanged() { chart.requestPaint() }
        function onAccentChanged() { chart.requestPaint() }
      }

      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var points = pts
        if (!points || points.length < 2) return
        var w = width, h = height

        var minW = Infinity, maxW = -Infinity
        for (var i = 0; i < points.length; i++) {
          var v = Number(points[i].weightKg)
          if (v < minW) minW = v
          if (v > maxW) maxW = v
        }
        // Keep at least a 1 kg window so small noise does not look dramatic.
        if (maxW - minW < 1) {
          var mid = (maxW + minW) / 2
          minW = mid - 0.5
          maxW = mid + 0.5
        }

        var startMs = Date.parse(points[0].date + "T00:00:00Z")
        var endMs = Date.parse(points[points.length - 1].date + "T00:00:00Z")
        if (!(endMs > startMs)) endMs = startMs + 1
        var xs = [], ys = []
        for (var j = 0; j < points.length; j++) {
          var t = Date.parse(points[j].date + "T00:00:00Z")
          xs.push(pad + (t - startMs) / (endMs - startMs) * (w - 2 * pad))
          ys.push(pad + (1 - (points[j].weightKg - minW) / (maxW - minW)) * (h - 2 * pad))
        }

        ctx.beginPath()
        ctx.moveTo(xs[0], ys[0])
        for (var k = 0; k < xs.length - 1; k++) {
          var x0 = xs[k === 0 ? 0 : k - 1], y0 = ys[k === 0 ? 0 : k - 1]
          var x3 = xs[k + 2 < xs.length ? k + 2 : k + 1], y3 = ys[k + 2 < ys.length ? k + 2 : k + 1]
          ctx.bezierCurveTo(
            xs[k] + (xs[k + 1] - x0) / 6, ys[k] + (ys[k + 1] - y0) / 6,
            xs[k + 1] - (x3 - xs[k]) / 6, ys[k + 1] - (y3 - ys[k]) / 6,
            xs[k + 1], ys[k + 1])
        }
        ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.55)
        ctx.lineWidth = 1.5
        ctx.lineJoin = "round"
        ctx.lineCap = "round"
        ctx.stroke()

        var lx = xs[xs.length - 1], ly = ys[ys.length - 1]
        ctx.beginPath()
        ctx.arc(lx, ly, 3, 0, Math.PI * 2)
        ctx.fillStyle = root.accent
        ctx.fill()
      }
    }

    Text {
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      visible: !chart.visible
      text: root.entries.length === 0
        ? "Log your weight in Setrai to see a trend here."
        : "Log one more entry to see a trend."
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }
}
