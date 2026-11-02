import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.services

// A porthole onto the weather outside: the card takes the colour of the sky out there,
// its horizon high in daylight and low at night.
Item {
    id: root

    property var options: ({})
    readonly property var now: Weather.look(Weather.code, Weather.day)

    implicitWidth: 330
    implicitHeight: Weather.known ? 206 : 120

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.cardOpen; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
    }

    HandCard {
        anchors.fill: parent
        seed: "weather"
        tint: Weather.known ? root.now.tint : "#a9a4ad"
        rise: Weather.day ? 0.3 : 0.08
        alive: Planet.pageEmpty
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Text {
                text: Weather.known ? `${Math.round(Weather.temperature)}°` : "–"
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 54
                font.weight: Font.Light
                renderType: Text.CurveRendering
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Icon {
                    name: root.now.icon
                    size: 26
                }

                Text {
                    Layout.fillWidth: true
                    text: Weather.known ? root.now.label : Weather.failed || Lang.t("On regarde le ciel…")
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 15
                }

                Text {
                    visible: Weather.place !== ""
                    Layout.fillWidth: true
                    text: Weather.place
                    elide: Text.ElideRight
                    color: Qt.alpha(Theme.text, 0.65)
                    font.family: Theme.font
                    font.pixelSize: 12
                }
            }
        }

        RowLayout {
            visible: Weather.known
            Layout.fillWidth: true

            // Each hour gets an equal share of the width
            Repeater {
                model: Weather.hours.slice(0, 5)

                Item {
                    id: hour

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: column.implicitHeight

                    ColumnLayout {
                        id: column

                        readonly property var modelData: hour.modelData

                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Config.time(modelData.time, { suffix: false })
                            color: Qt.alpha(Theme.text, 0.6)
                            font.family: Theme.font
                            font.pixelSize: 11
                        }

                        Icon {
                            Layout.alignment: Qt.AlignHCenter
                            name: Weather.look(modelData.code, modelData.day).icon
                            size: 18
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: `${Math.round(modelData.temperature)}°`
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}
