// Lucide `dumbbell` — https://lucide.dev/icons/dumbbell (ISC license).
// Paths copied verbatim from upstream so the icon stays recolorable at
// runtime; recoloring an Image-loaded SVG would need Qt5Compat.
import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property real size: 14
  property color iconColor: "white"
  property real strokeWidth: 2

  implicitWidth: size
  implicitHeight: size

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    transformOrigin: Item.TopLeft
    scale: root.size / 24

    ShapePath {
      strokeWidth: root.strokeWidth
      strokeColor: root.iconColor
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathSvg { path: "M17.596 12.768a2 2 0 1 0 2.829-2.829l-1.768-1.767a2 2 0 0 0 2.828-2.829l-2.828-2.828a2 2 0 0 0-2.829 2.828l-1.767-1.768a2 2 0 1 0-2.829 2.829z" }
    }
    ShapePath {
      strokeWidth: root.strokeWidth
      strokeColor: root.iconColor
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathSvg { path: "M2.5 21.5 l1.4 -1.4" }
    }
    ShapePath {
      strokeWidth: root.strokeWidth
      strokeColor: root.iconColor
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathSvg { path: "M20.1 3.9 l1.4 -1.4" }
    }
    ShapePath {
      strokeWidth: root.strokeWidth
      strokeColor: root.iconColor
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathSvg { path: "M5.343 21.485a2 2 0 1 0 2.829-2.828l1.767 1.768a2 2 0 1 0 2.829-2.829l-6.364-6.364a2 2 0 1 0-2.829 2.829l1.768 1.767a2 2 0 0 0-2.828 2.829z" }
    }
    ShapePath {
      strokeWidth: root.strokeWidth
      strokeColor: root.iconColor
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathSvg { path: "M9.6 14.4 l4.8 -4.8" }
    }
  }
}
