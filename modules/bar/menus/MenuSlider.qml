import QtQuick
import qs.config
import qs.modules.bar
import qs.services

// A fine line with a star riding on it, so it matches everything else up here.
Item {
    id: root

    property real value: 0
    property real maximum: 1
    property color tint: Menus.tint
    property bool entering: true // settles in like the rest of a menu
    readonly property real ratio: Math.max(0, Math.min(1, value / maximum))

    signal moved(real value)

    implicitHeight: 28
    implicitWidth: 240

    Entrance {
        item: root
        active: root.entering
    }

    // A proper track you can see from across the room, not just a line
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Theme.barThickness
        radius: height / 2
        color: Qt.alpha(root.tint, 0.18)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(height, parent.width * root.ratio)
        height: Theme.barThickness
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(root.tint, 0.5) }
            GradientStop { position: 1; color: root.tint }
        }
    }

    Star {
        x: parent.width * root.ratio - size
        y: parent.height / 2 - size
        size: 9
        lit: true
        animated: false
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor

        function pick(mouse) {
            root.moved(Math.max(0, Math.min(1, mouse.x / width)) * root.maximum);
        }

        onPressed: mouse => pick(mouse)
        onPositionChanged: mouse => pick(mouse)
    }
}
