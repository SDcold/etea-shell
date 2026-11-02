import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar

// A heading inside a settings page.
RowLayout {
    id: root

    property string text: ""

    Layout.fillWidth: true
    Layout.topMargin: 14
    spacing: 10

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
        font.pixelSize: 16
        font.weight: Font.Medium
    }
}
