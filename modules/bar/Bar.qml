import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// The bar, at the top or the bottom. Config.barLayout says what goes on each end and in the middle.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData
        property Item leftCorner: null
        property Item rightCorner: null
        // Where the bar itself sits in this taller surface: the halos need room on the screen side
        readonly property real line: Theme.barOnTop ? Theme.barGap : implicitHeight - Theme.barGap - Theme.barHeight
        readonly property real windowY: Theme.barOnTop ? 0 : (modelData?.height ?? 0) - implicitHeight

        screen: modelData
        color: "transparent"
        // The surface runs taller than the space it reserves, so halos have room to fade out
        implicitHeight: Theme.barReserve + Theme.barGlowRoom
        exclusiveZone: Theme.barReserve
        WlrLayershell.namespace: "etea:bar"

        // Staying awake is tied to a window that's always on screen, and the bar always is
        IdleInhibitor {
            window: bar
            enabled: Wake.on
        }

        anchors {
            top: Theme.barOnTop
            bottom: !Theme.barOnTop
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

        // The islands: each group of modules on its own little card of sky
        Repeater {
            model: Config.barStyle === "islands" ? [left, center, right] : []

            HandCard {
                required property Item modelData
                readonly property real pad: Math.round(Theme.barHeight * 0.4)

                visible: modelData.width > 0 && modelData.visibleChildren.length > 1
                x: modelData.x - pad
                y: bar.line
                width: modelData.width + pad * 2
                height: Theme.barHeight
                radius: Theme.barHeight / 2
                rise: 0
                ink: 0.42
                starSpacing: 0
                starScale: 0.62
                seed: `bar-${modelData.x}`
            }
        }

        // The band: one long card of sky across the screen
        HandCard {
            visible: Config.barStyle === "band"
            x: 8
            y: bar.line
            width: bar.width - 16
            height: Theme.barHeight
            radius: Theme.barHeight / 2
            rise: 0
            ink: 0.42
            starSpacing: 420
            starScale: 0.62
            seed: "bar"
        }

        // The top corners open the side panels
        Repeater {
            model: Config.hotCorners ? ["left", "right"] : []

            MouseArea {
                id: corner

                required property string modelData
                readonly property bool isLeft: modelData === "left"

                x: isLeft ? 0 : bar.width - width
                y: Theme.barOnTop ? 0 : bar.line - Theme.barGap
                width: Theme.barSide
                height: Theme.barReserve
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: Menus.togglePanel(modelData)
                Component.onCompleted: isLeft ? bar.leftCorner = corner : bar.rightCorner = corner
                Component.onDestruction: isLeft ? bar.leftCorner = null : bar.rightCorner = null

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

        BarRegion {
            id: left

            x: Theme.barSide
            y: bar.line
            modules: Config.barLayout.left ?? []
            monitorName: bar.modelData.name
            windowY: bar.windowY
        }

        BarRegion {
            id: center

            anchors.horizontalCenter: parent.horizontalCenter
            y: bar.line
            modules: Config.barLayout.center ?? []
            monitorName: bar.modelData.name
            windowY: bar.windowY
        }

        BarRegion {
            id: right

            anchors.right: parent.right
            anchors.rightMargin: Theme.barSide
            y: bar.line
            modules: Config.barLayout.right ?? []
            monitorName: bar.modelData.name
            windowY: bar.windowY
        }
    }
}
