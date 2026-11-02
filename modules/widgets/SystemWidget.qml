import QtQuick
import qs.config
import qs.modules.bar
import qs.services

// The ship's instruments: each reading is a star orbiting a little world, and the
// further round it has gone, the harder the machine is working.
Item {
    id: root

    implicitWidth: 300
    implicitHeight: 182

    HandCard {
        anchors.fill: parent
        seed: "system"
        tint: Machine.cpu > 0.8 ? "#f0705f" : "#8fc7e8"
        rise: 0.07 + Machine.cpu * 0.16
        alive: Planet.pageEmpty
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 16
        spacing: 26

        // Only ids here: values in the model would rebuild both gauges on every reading
        Repeater {
            model: [
                { id: "cpu", label: Lang.t("Processeur") },
                { id: "memory", label: Lang.t("Mémoire") }
            ]

            Item {
                id: gauge

                required property var modelData

                readonly property real value: modelData.id === "cpu" ? Machine.cpu : Machine.memory
                property real shown: 0

                width: 110
                height: 128

                // Behind windows the gauge holds still
                Binding on shown {
                    when: Planet.pageEmpty
                    value: gauge.value
                    restoreMode: Binding.RestoreNone
                }

                Behavior on shown {
                    NumberAnimation { duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
                }

                Component.onCompleted: shown = value

                onShownChanged: ring.requestPaint()

                Canvas {
                    id: ring

                    width: 100
                    height: 100
                    anchors.horizontalCenter: parent.horizontalCenter
                    renderStrategy: Canvas.Immediate
                    onPaint: {
                        const g = getContext("2d"), c = 50, r = 42, start = -Math.PI / 2;
                        g.reset();
                        g.lineCap = "round";
                        g.strokeStyle = String(Theme.windowLit);
                        g.globalAlpha = 0.18;
                        g.lineWidth = Theme.ringThickness;
                        g.beginPath();
                        g.arc(c, c, r, 0, Math.PI * 2);
                        g.stroke();
                        g.globalAlpha = 0.95;
                        g.lineWidth = Theme.ringThickness;
                        g.beginPath();
                        g.arc(c, c, r, start, start + gauge.shown * Math.PI * 2);
                        g.stroke();
                    }

                    Star {
                        readonly property real angle: gauge.shown * Math.PI * 2 - Math.PI / 2

                        x: 50 + 42 * Math.cos(angle) - size
                        y: 50 + 42 * Math.sin(angle) - size
                        size: 7
                        lit: true
                        animated: false
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Math.round(gauge.shown * 100)
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 22
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: gauge.modelData.label
                    color: Qt.alpha(Theme.text, 0.72)
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }
        }
    }
}
