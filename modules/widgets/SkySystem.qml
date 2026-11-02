import QtQuick
import qs.config
import qs.services

// The machine's vital signs, written straight onto the sky the way the time is.
Row {
    id: root

    property real sky: 1080
    property var options: ({}) // its entry in Config.widgets
    // Kept as text, so moving the widget doesn't rebuild its gauges
    readonly property string readings: (options?.readings ?? ["cpu", "memory"]).join()

    spacing: sky * 0.05

    Repeater {
        model: [
            { id: "cpu", label: Lang.t("Processeur") },
            { id: "memory", label: Lang.t("Mémoire") }
        ].filter(reading => root.readings.includes(reading.id))

        Column {
            id: reading

            required property var modelData

            readonly property real value: modelData.id === "cpu" ? Machine.cpu : Machine.memory
            readonly property color ink: shown > 0.85 ? "#f0947c" : Theme.skyInk
            property real shown: 0

            spacing: root.sky * 0.008

            // Behind windows the reading holds still: each glide redraws the whole sky
            Binding on shown {
                when: Planet.pageEmpty
                value: reading.value
                restoreMode: Binding.RestoreNone
            }

            Behavior on shown {
                NumberAnimation { duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
            }

            Component.onCompleted: shown = value

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
                renderType: Text.CurveRendering

                layer.enabled: true
                layer.smooth: true
                layer.textureSize: Qt.size(width * 2, height * 2) // drawn at double size so the curves come out smooth
                layer.effect: Dissolve {
                    from: 0.34
                    to: 0.92
                }
            }
        }
    }
}
