import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar

// A setting on one line: what it is on the left, how to change it on the right.
RowLayout {
    id: root

    property string label: ""
    property string hint: ""
    default property alias control: holder.data

    spacing: 20
    Layout.fillWidth: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 14
        }

        Text {
            visible: root.hint !== ""
            Layout.fillWidth: true
            text: root.hint
            wrapMode: Text.Wrap
            color: Qt.alpha(Theme.text, 0.6)
            font.family: Theme.font
            font.pixelSize: 12
        }
    }

    Item {
        id: holder

        Layout.preferredWidth: childrenRect.width
        Layout.preferredHeight: childrenRect.height
        Layout.alignment: Qt.AlignVCenter
    }
}
