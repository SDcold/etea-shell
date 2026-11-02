import QtQuick
import qs.config

// How everything in the bar answers the pointer: it grows a little and a small star
// lights up under it, on the screen side. A press pushes it in.
MouseArea {
    id: root

    property Item target: parent
    property real lift: pressed ? 0.9 : containsMouse ? 1.08 : 1

    anchors.fill: parent
    anchors.margins: -5
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Behavior on lift {
        NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
    }

    Binding {
        target: root.target
        property: "scale"
        value: root.lift
    }

    Star {
        x: root.width / 2 - size
        y: Theme.barOnTop ? root.height - 2 : -size * 2 + 2
        size: 2.5
        lit: true
        animated: false
        opacity: root.containsMouse ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.fast }
        }
    }
}
