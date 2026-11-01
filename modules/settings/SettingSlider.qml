import QtQuick
import qs.config
import qs.modules.bar.menus

// A setting you slide. The value shows beside the line as it moves.
SettingRow {
    id: root

    property real value: 0
    property real minimum: 0
    property real maximum: 1
    property string unit: ""
    property int decimals: 0
    property real shownAs: 1 // multiply what's stored before showing it, for percentages

    signal moved(real value)

    Row {
        spacing: 12

        MenuSlider {
            anchors.verticalCenter: parent.verticalCenter
            width: 220
            tint: Theme.windowLit
            value: root.value - root.minimum
            maximum: root.maximum - root.minimum
            onMoved: value => root.moved(root.minimum + value)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 58
            horizontalAlignment: Text.AlignRight
            text: (root.value * root.shownAs).toFixed(root.decimals) + root.unit
            color: Qt.alpha(Theme.text, 0.75)
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
