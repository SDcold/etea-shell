import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.modules.bar.menus

// An icon, a thick track and the value beside it.
RowLayout {
    id: root

    property string icon: ""
    property real value: 0
    property real maximum: 1
    property color tint: Theme.windowLit

    signal moved(real value)
    signal iconPressed()

    spacing: 12
    Layout.fillWidth: true

    Icon {
        name: root.icon
        size: 22

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onPressed: root.iconPressed()
        }
    }

    MenuSlider {
        Layout.fillWidth: true
        tint: root.tint
        value: root.value
        maximum: root.maximum
        onMoved: value => root.moved(value)
    }

    Text {
        Layout.preferredWidth: 34
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100)
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 13
        font.weight: Font.Medium
    }
}
