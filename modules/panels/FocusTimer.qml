import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.modules.settings
import qs.services

// A ring that fills as the time goes by, a star riding its edge.
ColumnLayout {
    id: root

    readonly property color tint: Focus.mode === "focus" ? "#ffc98a" : "#8fd6b4"

    spacing: 12

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 180
        implicitHeight: 180

        Canvas {
            id: ring

            anchors.fill: parent
            renderStrategy: Canvas.Immediate
            onPaint: {
                const g = getContext("2d"), c = width / 2, r = c - 12, start = -Math.PI / 2;
                g.reset();
                g.lineCap = "round";
                g.lineWidth = Theme.ringThickness + 2;
                g.strokeStyle = String(root.tint);
                g.globalAlpha = 0.16;
                g.beginPath();
                g.arc(c, c, r, 0, Math.PI * 2);
                g.stroke();
                g.globalAlpha = 0.95;
                g.beginPath();
                g.arc(c, c, r, start, start + Math.max(0.001, Focus.done) * Math.PI * 2);
                g.stroke();
            }

            Connections {
                target: Focus

                function onLeftChanged() {
                    ring.requestPaint();
                }

                function onModeChanged() {
                    ring.requestPaint();
                }
            }
        }

        Star {
            readonly property real angle: Focus.done * Math.PI * 2 - Math.PI / 2

            x: 90 + 78 * Math.cos(angle) - size
            y: 90 + 78 * Math.sin(angle) - size
            size: 9
            lit: Focus.running
            animated: false
        }

        Column {
            anchors.centerIn: parent

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Focus.clock()
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 38
                font.weight: Font.Light
                font.features: { "tnum": 1 }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Focus.mode === "focus" ? Lang.t("Concentration") : Lang.t("Pause")
                color: root.tint
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10

        SettingButton {
            label: Focus.running ? Lang.t("Pause") : Focus.left < Focus.length ? Lang.t("Reprendre") : Lang.t("Démarrer")
            onPicked: Focus.toggle()
        }

        SettingButton {
            label: Lang.t("Remettre à zéro")
            quiet: true
            onPicked: Focus.reset()
        }

        SettingButton {
            label: Focus.mode === "focus" ? Lang.t("Pause") : Lang.t("Travail")
            quiet: true
            onPicked: Focus.setMode(Focus.mode === "focus" ? "rest" : "focus")
        }
    }
}
