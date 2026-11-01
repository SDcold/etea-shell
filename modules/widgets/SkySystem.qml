import QtQuick
import qs.config
import qs.services

// The machine's vital signs, written straight onto the sky the way the time is.
Row {
    id: root

    property real sky: 1080

    spacing: sky * 0.05

    Repeater {
        model: [
            { id: "cpu", label: "Processeur" },
            { id: "memory", label: "Mémoire" }
        ]

        Column {
            id: reading

            required property var modelData

            readonly property real value: modelData.id === "cpu" ? Machine.cpu : Machine.memory
            readonly property color ink: value > 0.85 ? "#f0947c" : Theme.skyInk
            property real shown: value

            spacing: root.sky * 0.008

            Behavior on shown {
                NumberAnimation { duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
            }

            Text {
                text: reading.modelData.label
                color: reading.ink
                font.family: Theme.font
                font.pixelSize: root.sky * 0.016
                font.weight: Font.Medium
            }

            Rectangle {
                width: root.sky * 0.125
                height: Theme.barThickness
                radius: height / 2
                color: Qt.alpha(reading.ink, 0.2)

                Rectangle {
                    width: Math.max(parent.height, parent.width * reading.shown)
                    height: parent.height
                    radius: parent.radius
                    color: reading.ink
                }
            }

            Text {
                text: Math.round(reading.shown * 100)
                color: reading.ink
                font.family: Theme.font
                font.pixelSize: root.sky * 0.125
                font.weight: Font.Medium
                font.letterSpacing: -root.sky * 0.003

                layer.enabled: true
                layer.effect: Dissolve {
                    from: 0.34
                    to: 0.92
                }
            }
        }
    }
}
