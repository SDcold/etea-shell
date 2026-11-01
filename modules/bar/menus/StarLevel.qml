import QtQuick
import qs.modules.bar
import qs.services

// A strength or a level, told in stars: the stronger it is, the more of them shine.
Row {
    id: root

    property real level: 0

    spacing: 3

    Repeater {
        model: 4

        Star {
            required property int index

            anchors.verticalCenter: parent.verticalCenter
            size: 4
            lit: root.level > index / 4
            animated: false
            opacity: root.level > index / 4 ? 1 : 0.3
        }
    }
}
