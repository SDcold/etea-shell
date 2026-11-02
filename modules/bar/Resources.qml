import QtQuick
import qs.config
import qs.services

// How hard the machine is working: a small ring per resource, filling up as it climbs.
// The network is the odd one out, it shows its speed both ways.
Row {
    id: root

    readonly property bool wanted: Config.barResources.length > 0

    spacing: Theme.barSpacing

    // Short and steady: the number never makes the bar jump around
    function rate(bytes) {
        return Machine.rate(bytes);
    }

    TextMetrics {
        id: widest

        font.family: Theme.font
        font.pixelSize: Theme.textSize - 1
        font.features: { "tnum": 1 }
        text: "88,8 Mo/s"
    }

    Repeater {
        model: Config.barResources

        Row {
            id: resource

            required property string modelData
            readonly property bool speed: modelData === "network"
            readonly property real value: modelData === "cpu" ? Machine.cpu : Machine.memory
            readonly property color tint: value > 0.85 ? "#f0947c" : Theme.text

            spacing: 6

            Item {
                visible: !resource.speed
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconSize + 4
                height: Theme.iconSize + 4

                Canvas {
                    id: ring

                    anchors.fill: parent
                    renderStrategy: Canvas.Immediate
                    onPaint: {
                        const g = getContext("2d"), c = width / 2, r = c - 2, start = -Math.PI / 2;
                        g.reset();
                        g.lineCap = "round";
                        g.lineWidth = 2.5;
                        g.strokeStyle = String(resource.tint);
                        g.globalAlpha = 0.22;
                        g.beginPath();
                        g.arc(c, c, r, 0, Math.PI * 2);
                        g.stroke();
                        g.globalAlpha = 1;
                        g.beginPath();
                        g.arc(c, c, r, start, start + Math.max(0.02, resource.value) * Math.PI * 2);
                        g.stroke();
                    }

                    Connections {
                        target: resource

                        function onValueChanged() {
                            ring.requestPaint();
                        }
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    name: Config.resourceChoices.find(choice => choice.id === resource.modelData)?.icon ?? ""
                    size: Theme.iconSize - 9
                    tint: resource.tint
                }
            }

            Repeater {
                model: resource.speed ? [["down", Machine.download], ["up", Machine.upload]] : []

                Row {
                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: parent.modelData[0]
                        size: Theme.iconSize - 5
                        tint: Theme.textSoft
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: widest.width
                        text: root.rate(parent.modelData[1])
                        color: Theme.textSoft
                        font: widest.font
                    }
                }
            }

            Text {
                visible: Config.barPercent && !resource.speed
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(resource.value * 100) + "%"
                color: resource.tint
                font.family: Theme.font
                font.pixelSize: Theme.textSize
                font.features: { "tnum": 1 }
            }
        }
    }
}
