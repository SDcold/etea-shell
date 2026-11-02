import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.modules.bar.menus
import qs.services

// The logbook: the month and its moon, what you have to do, and a timer to get it done.
ColumnLayout {
    id: root

    spacing: 14

    CalendarMenu {
        Layout.alignment: Qt.AlignHCenter
    }

    SectionTitle {
        text: Tasks.items.length ? `${Lang.t("Tâches")} · ${Tasks.items.filter(task => !task.done).length}` : Lang.t("Tâches")
        action: Tasks.items.some(task => task.done) ? Lang.t("Ranger les faites") : ""
        onActed: Tasks.items = Tasks.items.filter(task => !task.done)
    }

    // A star you can tick: it lights up once the task is done
    Repeater {
        model: Tasks.items

        Item {
            id: task

            required property var modelData
            required property int index

            Layout.fillWidth: true
            implicitHeight: label.implicitHeight + 16

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Theme.windowLit
                opacity: pointer.containsMouse ? 0.07 : 0
            }

            Star {
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                size: 8
                lit: task.modelData.done
                animated: false
                opacity: task.modelData.done ? 1 : 0.5
            }

            Text {
                id: label

                x: 36
                width: parent.width - 72
                anchors.verticalCenter: parent.verticalCenter
                text: task.modelData.text
                wrapMode: Text.Wrap
                font.strikeout: task.modelData.done
                color: task.modelData.done ? Qt.alpha(Theme.text, 0.45) : Theme.text
                font.family: Theme.font
                font.pixelSize: 14
            }

            MouseArea {
                id: pointer

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: Tasks.toggle(task.index)
            }

            Icon {
                visible: pointer.containsMouse || remove.containsMouse
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                name: "close"
                size: 16

                MouseArea {
                    id: remove

                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: Tasks.remove(task.index)
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: 14
        color: Qt.alpha(Theme.windowLit, 0.08)
        border.width: 1
        border.color: Qt.alpha(Theme.windowLit, entry.activeFocus ? 0.6 : 0.18)

        Icon {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            name: "add"
            size: 18
        }

        TextInput {
            id: entry

            x: 40
            width: parent.width - 52
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 14
            onAccepted: {
                Tasks.add(text);
                text = "";
            }

            Text {
                visible: entry.text === "" && !entry.activeFocus
                text: Lang.t("Ajouter une tâche")
                color: Qt.alpha(Theme.text, 0.5)
                font: entry.font
            }
        }
    }

    SectionTitle {
        text: Lang.t("Minuteur")
    }

    FocusTimer {
        Layout.fillWidth: true
    }
}
