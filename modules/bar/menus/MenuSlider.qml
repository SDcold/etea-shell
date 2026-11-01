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
    readonly property real ratio: Math.max(0, Math.min(1, value / maximum))

    signal moved(real value)

    implicitHeight: 26
    implicitWidth: 240

    Entrance {
        item: root
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 2
        radius: 1
        color: Qt.alpha(root.tint, 0.22)
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * root.ratio
        height: 2
        radius: 1
        color: root.tint
    }

    Star {
        x: parent.width * root.ratio - size
        y: parent.height / 2 - size
        size: 8
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
