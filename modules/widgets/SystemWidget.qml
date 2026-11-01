import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.services

// The machine's vital signs, each one a star riding along its line.
Item {
    implicitWidth: 250
    implicitHeight: readings.implicitHeight + 40

    HandCard {
        anchors.fill: parent
        seed: "system"
    }

    ColumnLayout {
        id: readings

        x: 20
        y: 20
        width: parent.width - 40
        spacing: 12

        Repeater {
            model: [
                { label: "Processeur", value: Machine.cpu },
                { label: "Mémoire", value: Machine.memory }
            ]

            ColumnLayout {
                id: reading

                required property var modelData

                spacing: 2

                RowLayout {
                    Text {
                        Layout.fillWidth: true
                        text: reading.modelData.label
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 15
                    }

                    Text {
                        text: `${Math.round(reading.modelData.value * 100)} %`
                        color: Theme.windowLit
                        font.family: Theme.font
                        font.pixelSize: 15
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 14

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 1
                        color: Qt.alpha(Theme.windowLit, 0.25)
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * reading.modelData.value
                        height: 1
                        color: Theme.windowLit
                    }

                    Star {
                        x: parent.width * reading.modelData.value - size
                        y: parent.height / 2 - size
                        size: 5
                        lit: true
                        animated: false

                        Behavior on x {
                            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
