import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.bar

// The month at a glance. Today is the one with a star on it.
ColumnLayout {
    id: root

    property date shown: new Date()
    readonly property date today: new Date()
    readonly property var locale: Qt.locale(Config.locale)

    readonly property var days: {
        const first = new Date(shown.getFullYear(), shown.getMonth(), 1);
        const offset = (first.getDay() + 6) % 7;
        const cells = [];
        for (let i = 0; i < 42; i++)
            cells.push(new Date(shown.getFullYear(), shown.getMonth(), i - offset + 1));
        return cells;
    }

    function shift(months) {
        shown = new Date(shown.getFullYear(), shown.getMonth() + months, 1);
    }

    spacing: 8
    width: 300

    RowLayout {
        Layout.fillWidth: true

        Icon {
            name: "caret-left"
            size: 20

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onPressed: root.shift(-1)
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.locale.toString(root.shown, "MMMM yyyy")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 18
        }

        Icon {
            name: "caret-right"
            size: 20

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onPressed: root.shift(1)
            }
        }
    }

    GridLayout {
        columns: 7
        rowSpacing: 0
        columnSpacing: 0
        Layout.fillWidth: true

        Repeater {
            model: ["lun", "mar", "mer", "jeu", "ven", "sam", "dim"]

            Text {
                required property string modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 28
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: Theme.windowLit
                font.family: Theme.font
                font.pixelSize: 12
            }
        }

        Repeater {
            model: root.days

            Item {
                id: cell

                required property var modelData

                readonly property bool isToday: modelData.toDateString() === root.today.toDateString()

                Layout.fillWidth: true
                Layout.preferredHeight: 36

                Star {
                    visible: cell.isToday
                    anchors.centerIn: parent
                    size: 19
                    lit: true
                    animated: false
                    opacity: 0.55
                }

                Text {
                    anchors.centerIn: parent
                    text: cell.modelData.getDate()
                    color: cell.isToday ? "#1c1208" : Qt.alpha(Theme.text, cell.modelData.getMonth() === root.shown.getMonth() ? 0.9 : 0.3)
                    font.family: Theme.font
                    font.pixelSize: 15
                }
            }
        }
    }
}
