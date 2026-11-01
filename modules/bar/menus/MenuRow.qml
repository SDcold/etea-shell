import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.services

// One line in a list: something you can pick, with a detail on the right.
Item {
    id: root

    property string label: ""
    property string detail: ""
    property bool active: false
    property real level: -1 // shown as a row of stars, when there is one

    signal picked()

    implicitWidth: 280
    implicitHeight: 34

    Entrance {
        item: root
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: 11
        color: Menus.tint
        opacity: root.active ? 0.18 : pointer.containsMouse ? 0.09 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.fast }
        }
    }

    StarRipple {
        id: ripple
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        Star {
            visible: root.active
            Layout.alignment: Qt.AlignVCenter
            size: 6
            lit: true
            animated: false
        }

        Text {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
            color: root.active ? Theme.text : Qt.alpha(Theme.text, 0.75)
            font.family: Theme.font
            font.pixelSize: 13
        }

        StarLevel {
            visible: root.level >= 0
            level: root.level
        }

        Text {
            text: root.detail
            color: Qt.alpha(Theme.text, 0.5)
            font.family: Theme.font
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            ripple.burst(mouse.x, mouse.y);
            root.picked();
        }
    }
}
