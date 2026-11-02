import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// The bar: pages on the left, time in the middle, system on the right.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData
        property Item leftCorner: null
        property Item rightCorner: null

        screen: modelData
        color: "transparent"
        // The surface runs taller than the space it reserves, so halos have room to fade out
        implicitHeight: Theme.barGap + Theme.barHeight + Theme.barGlowRoom
        exclusiveZone: Theme.barGap + Theme.barHeight
        WlrLayershell.namespace: "etea:bar"

        anchors {
            top: true
            left: true
            right: true
        }

        // Clicks fall through the gaps and reach the desktop
        mask: Region {
            Region { item: left }
            Region { item: center }
            Region { item: right }
            Region { item: bar.leftCorner }
            Region { item: bar.rightCorner }
        }

        // The top corners open the side panels, which pour out of them
        Repeater {
            model: ["left", "right"]

            MouseArea {
                id: corner

                required property string modelData
                readonly property bool isLeft: modelData === "left"

                x: isLeft ? 0 : bar.width - width
                width: Theme.barSide
                height: Theme.barGap + Theme.barHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: Menus.togglePanel(modelData)
                Component.onCompleted: isLeft ? bar.leftCorner = corner : bar.rightCorner = corner

                Star {
                    anchors.centerIn: parent
                    size: 5
                    lit: true
                    animated: false
                    opacity: corner.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.fast }
                    }
                }
            }
        }

        Pages {
            id: left

            x: Theme.barSide
            y: Theme.barGap
            monitorName: bar.modelData.name
        }

        Glow {
            id: center

            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.barGap

            Clock {}
            Media {}
        }

        Glow {
            id: right

            anchors.right: parent.right
            anchors.rightMargin: Theme.barSide
            y: Theme.barGap

            Tray {}
            Status {}
        }
    }
}
