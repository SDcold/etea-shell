import QtQuick
import QtQuick.Layouts
import qs.config

// One line in a list: something you can pick, with a detail on the right.
Item {
    id: root

    property string label: ""
    property string detail: ""
    property bool active: false

    signal picked()

    implicitWidth: 280
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: 9
        color: Theme.windowLit
        opacity: root.active ? 0.14 : pointer.containsMouse ? 0.07 : 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        Text {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
            color: root.active ? Theme.text : Qt.alpha(Theme.text, 0.75)
            font.family: Theme.font
            font.pixelSize: 15
        }

        Text {
            text: root.detail
            color: Qt.alpha(Theme.text, 0.5)
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.picked()
    }
}
