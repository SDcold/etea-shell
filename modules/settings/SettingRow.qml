import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar

// A setting on one line: what it is on the left, how to change it on the right. A star
// beside it sleeps while the setting is as it came, and lights once it's yours.
RowLayout {
    id: root

    property string label: ""
    property string hint: ""
    property string key: "" // the saved value it changes, if it's one of Config's
    property var words: [] // other words people would search it by, beside the key's own
    readonly property bool yours: key !== "" && Config.changed(key)
    // A search that brought you here lights the row for a moment
    property bool found: false
    default property alias control: holder.data

    objectName: "setting"

    spacing: 20
    Layout.fillWidth: true

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            id: label

            Layout.fillWidth: true
            text: root.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 14

            // Hung in the margin, on the label's first line, out of the layout's way
            Star {
                x: -11 - size // inside the room the page keeps on its left
                y: label.implicitHeight / Math.max(1, label.lineCount) / 2 - size
                visible: root.key !== ""
                size: root.found ? 6 : root.yours ? 4 : 3
                lit: root.yours || root.found
                animated: false

                Behavior on size {
                    NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
                }
            }
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
