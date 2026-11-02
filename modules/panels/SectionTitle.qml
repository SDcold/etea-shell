import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar

// A section heading, with an optional action on the right.
RowLayout {
    id: root

    property string text: ""
    property string action: ""
    property color tint: Theme.windowLit

    signal acted()

    Layout.fillWidth: true
    Layout.topMargin: 6

    Star {
        Layout.alignment: Qt.AlignVCenter
        size: 5
        lit: true
        animated: false
    }

    Text {
        Layout.fillWidth: true
        text: root.text
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 15
        font.weight: Font.Medium
    }

    Text {
        visible: root.action !== ""
        text: root.action
        color: root.tint
        font.family: Theme.font
        font.pixelSize: 12

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onPressed: root.acted()
        }
    }
}
