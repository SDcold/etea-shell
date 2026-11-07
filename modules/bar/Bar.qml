import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

// The bar, at the top or the bottom. Config.barLayout says what goes on each end and in the middle.
Variants {
    model: Config.ready ? Quickshell.screens : []

    PanelWindow {
        id: bar

        required property var modelData
        property Item leftCorner: null
        property Item rightCorner: null
        // Where the bar itself sits in this taller surface: the halos need room on the screen side
        readonly property real line: Theme.barOnTop ? Theme.barGap : implicitHeight - Theme.barGap - Theme.barHeight
        readonly property real windowY: Theme.barOnTop ? 0 : (modelData?.height ?? 0) - implicitHeight

        // Out of the way, always or only over a fullscreen window, until the mouse comes for it
        readonly property bool fullscreenHere: Hyprland.monitorFor(modelData)?.activeWorkspace?.hasFullscreen ?? false
        readonly property bool hides: Config.barHide === "always" || (Config.barHide === "fullscreen" && fullscreenHere)
        readonly property bool wanted: !hides || hover.hovered || Menus.open !== "" || Menus.leftOpen || Menus.rightOpen
        property bool shown: !hides
        property bool calling: false // the corner stars, lit just before the bar comes back
        property real seen: shown ? 1 : 0

        Behavior on seen {
            NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic }
        }

        onWantedChanged: {
            if (!hides) {
                arrival.stop();
                calling = false;
                shown = true;
            } else if (wanted) {
                leave.stop();
                if (!shown && !arrival.running)
                    arrival.start();
            } else {
                leave.restart();
            }
        }

        screen: modelData
        color: "transparent"
        // The surface runs taller than the space it reserves, so halos have room to fade out
        implicitHeight: Theme.barReserve + Theme.barGlowRoom
        exclusiveZone: Theme.barSpace
        // A fullscreen window covers the top layer, so the bar climbs over it to come back
        WlrLayershell.layer: hides && fullscreenHere ? WlrLayer.Overlay : WlrLayer.Top
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

        // Clicks fall through the gaps and reach the desktop. Hiding, the bar only listens along its edge.
        mask: Region {
            Region { item: bar.hides ? zone : null }
            Region { item: bar.hides ? null : left }
            Region { item: bar.hides ? null : center }
            Region { item: bar.hides ? null : right }
            Region { item: bar.hides ? null : bar.leftCorner }
            Region { item: bar.hides ? null : bar.rightCorner }
        }

        HoverHandler {
            id: hover
        }

        // The corners light up first, then the bar follows
        SequentialAnimation {
            id: arrival

            PropertyAction { target: bar; property: "calling"; value: true }
            PauseAnimation { duration: Theme.normal }
            PropertyAction { target: bar; property: "shown"; value: true }
            PauseAnimation { duration: Theme.normal }
            PropertyAction { target: bar; property: "calling"; value: false }
        }

        Timer {
            id: leave

            interval: 500
            onTriggered: {
                if (bar.wanted)
                    return;
                arrival.stop();
                bar.calling = false;
                bar.shown = false;
            }
        }

        // Where the mouse finds the bar while it's away: a thin line on the screen edge, then the whole strip once it's back
        Item {
            id: zone

            y: Theme.barOnTop ? 0 : bar.implicitHeight - height
            width: bar.width
            height: bar.shown ? Theme.barReserve : 2
        }

        Item {
            anchors.fill: parent
            opacity: bar.seen
            transform: Translate {
                y: (1 - bar.seen) * (Theme.barOnTop ? -8 : 8)
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

            BarRegion {
                id: left

                x: Theme.barSide
                y: bar.line
                modules: Config.barLayout.left ?? []
                monitorName: bar.modelData.name
                windowY: bar.windowY
                span: bar.width
            }

            BarRegion {
                id: center

                anchors.horizontalCenter: parent.horizontalCenter
                y: bar.line
                modules: Config.barLayout.center ?? []
                monitorName: bar.modelData.name
                windowY: bar.windowY
                span: bar.width
            }

            BarRegion {
                id: right

                anchors.right: parent.right
                anchors.rightMargin: Theme.barSide
                y: bar.line
                modules: Config.barLayout.right ?? []
                monitorName: bar.modelData.name
                windowY: bar.windowY
                span: bar.width
            }
        }

        // The top corners open the side panels. A hidden bar keeps them, to show where to aim.
        Repeater {
            model: Config.hotCorners || bar.hides ? ["left", "right"] : []

            MouseArea {
                id: corner

                required property string modelData
                readonly property bool isLeft: modelData === "left"

                x: isLeft ? 0 : bar.width - width
                y: Theme.barOnTop ? 0 : bar.line - Theme.barGap
                width: Theme.barSide
                height: Theme.barReserve
                enabled: Config.hotCorners
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
                    opacity: corner.containsMouse || bar.calling ? 1 : 0
                    scale: bar.calling ? 1.5 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.fast }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack }
                    }
                }
            }
        }
    }
}
