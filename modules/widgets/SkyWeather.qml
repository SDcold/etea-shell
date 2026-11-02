import QtQuick
import qs.config
import qs.modules.bar
import qs.services

// The weather written across the sky: how warm it is, large and melting like the time,
// what the sky is doing, and the hours to come in a quiet line underneath.
Column {
    id: root

    property real sky: 1080
    property var options: ({})
    readonly property var now: Weather.look(Weather.code, Weather.day)

    spacing: sky * 0.012

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.sky * 0.024

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.known ? `${Math.round(Weather.temperature)}°` : "–"
            color: Theme.skyInk
            font.family: Theme.font
            font.pixelSize: root.sky * 0.11
            font.weight: Font.Medium
            font.letterSpacing: -root.sky * 0.003
            renderType: Text.CurveRendering

            layer.enabled: true
            layer.smooth: true
            layer.textureSize: Qt.size(width * 2, height * 2) // drawn at double size so the curves come out smooth
            layer.effect: Dissolve {
                from: 0.34
                to: 0.95
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.sky * 0.004

            Icon {
                name: root.now.icon
                size: Math.round(root.sky * 0.036)
                tint: Theme.skyInk
            }

            Text {
                text: Weather.known ? root.now.label : Weather.failed || Lang.t("On regarde le ciel…")
                color: Theme.skyInk
                font.family: Theme.font
                font.pixelSize: root.sky * 0.02
                font.weight: Font.Medium
            }

            Text {
                visible: Weather.place !== ""
                text: Weather.place
                color: Qt.alpha(Theme.skyInk, 0.7)
                font.family: Theme.font
                font.pixelSize: root.sky * 0.014
            }
        }
    }

    // The next hours, each one a column
    Row {
        visible: Weather.known
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.sky * 0.03

        Repeater {
            model: Weather.hours.slice(0, 5)

            Column {
                required property var modelData

                spacing: root.sky * 0.004

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Config.time(modelData.time, { suffix: false })
                    color: Qt.alpha(Theme.skyInk, 0.65)
                    font.family: Theme.font
                    font.pixelSize: root.sky * 0.012
                }

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: Weather.look(modelData.code, modelData.day).icon
                    size: Math.round(root.sky * 0.02)
                    tint: Theme.skyInk
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: `${Math.round(modelData.temperature)}°`
                    color: Theme.skyInk
                    font.family: Theme.font
                    font.pixelSize: root.sky * 0.015
                    font.weight: Font.Medium
                }
            }
        }
    }
}
