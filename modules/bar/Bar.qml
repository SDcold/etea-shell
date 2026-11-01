import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// The bar: pages on the left, time in the middle, system on the right.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData

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

            Status {}
        }
    }
}
