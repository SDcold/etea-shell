import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar

// One thing worth knowing, and its value. Nothing to click, so nothing lights up.
RowLayout {
    id: root

    property string label: ""
    property string value: ""

    implicitWidth: 280
    implicitHeight: 26
    spacing: 12

    Entrance {
        item: root
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        text: root.label
        elide: Text.ElideRight
        color: Qt.alpha(Theme.text, 0.6)
        font.family: Theme.font
        font.pixelSize: 12
    }

    Text {
        Layout.rightMargin: 8
        Layout.maximumWidth: 200
        text: root.value
        elide: Text.ElideMiddle
        horizontalAlignment: Text.AlignRight
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 12
        font.features: { "tnum": 1 }
    }
}
