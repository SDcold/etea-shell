import QtQuick
import QtQuick.Effects
import Quickshell
import qs.config

// One of our icons, tinted to whatever colour it's sitting in.
Item {
    id: root

    required property string name
    property int size: 20
    property color tint: Theme.text

    implicitWidth: size
    implicitHeight: size

    Image {
        id: picture

        anchors.fill: parent
        visible: false
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        source: root.name ? "file://" + Quickshell.shellPath(`assets/icons/${root.name}.svg`) : ""
    }

    MultiEffect {
        anchors.fill: parent
        source: picture
        colorization: 1
        colorizationColor: root.tint
        brightness: 1
    }
}
