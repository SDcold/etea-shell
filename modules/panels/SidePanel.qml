import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.services

// A side panel that pours out of the edge of the screen: it bulges out, runs down,
// then lets go of the edge and floats. Closing pours it back in.
Scope {
    id: root

    required property string side // "left" or "right"
    required property bool open
    property color tint: Theme.windowLit
    property Component content

    signal closeRequested()

    PanelWindow {
        id: window

        property real progress: root.open ? 1 : 0
        readonly property bool right: root.side === "right"

        function clamp(value) {
            return Math.max(0, Math.min(1, value));
        }

        function lerp(from, to, amount) {
            return from + (to - from) * amount;
        }

        readonly property rect target: {
            const top = Theme.barGap + Theme.barHeight + 12;
            return Qt.rect(right ? width - Theme.barSide - Theme.panelWidth : Theme.barSide, top, Theme.panelWidth, height - top - 14);
        }

        // Out of the edge with a little overshoot, then down. Closing rises first, then sinks back in.
        readonly property real reach: {
            const t = clamp(progress / 0.7);
            if (!root.open)
                return t * t * (3 - 2 * t);
            const c = 1.3, u = t - 1;
            return 1 + (c + 1) * u * u * u + c * u * u;
        }
        readonly property real drop: {
            const t = clamp((progress - 0.08) / 0.92);
            return root.open ? 1 - Math.pow(1 - t, 4) : t * t * (3 - 2 * t);
        }
        // Stuck to the edge while it moves, free once it has landed
        readonly property real held: 1 - clamp((progress - 0.75) / 0.25)
        // It comes from behind the edge and goes back there, so it never pops up or dies on screen
        readonly property rect shape: {
            const w = target.width * reach;
            const outer = right ? lerp(width + 30, target.x + target.width, reach) : lerp(-30, target.x, reach);
            return Qt.rect(right ? outer - w : outer, target.y, w, lerp(90, target.height, drop));
        }
        // The edge it pours out of, just off screen, sliding away as it lets go
        readonly property rect edge: {
            const away = (1 - held) * 70;
            return Qt.rect(right ? width + away : -40 - away, shape.y, 40, shape.height);
        }

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: progress > 0.001
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: `etea:panel-${root.side}`
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Behavior on progress {
            NumberAnimation {
                duration: root.open ? Theme.panelOpen : Theme.panelClose
            }
        }

        // Only the panel itself catches the mouse
        mask: Region {
            item: hitArea
        }

        HyprlandFocusGrab {
            windows: [window]
            active: root.open
            onCleared: root.closeRequested()
        }

        Item {
            id: hitArea

            x: window.shape.x
            y: window.shape.y
            width: window.shape.width
            height: window.shape.height
        }

        ShaderEffect {
            id: drawer

            readonly property real pad: 6

            property color deep: Theme.cardDeep
            property color tint: root.tint
            property color ink: root.tint
            property vector4d anchorBox: Qt.vector4d(window.edge.x - x, window.edge.y - y, window.edge.width, window.edge.height)
            property vector4d panelBox: Qt.vector4d(window.shape.x - x, window.shape.y - y, window.shape.width, window.shape.height)
            property vector2d resolution: Qt.vector2d(width, height)
            property real anchorRadius: 0
            property real panelRadius: 26
            property real blend: 30 + 70 * window.held // a thick neck to the edge that thins out and snaps
            property real anchorAmount: window.held > 0 ? 1 : 0
            property real time: 0
            property real seed: root.side === "right" ? 4.7 : 1.3
            property real rise: 0.06
            property real inkAmount: window.clamp((window.progress - 0.85) / 0.15)

            x: window.right ? window.shape.x - pad : 0
            y: window.shape.y - pad
            width: window.right ? window.width - x : window.shape.x + window.shape.width + pad
            height: window.shape.height + pad * 2
            fragmentShader: Qt.resolvedUrl("../../shaders/drawer.frag.qsb")

            Behavior on tint {
                ColorAnimation { duration: 600 }
            }

            FrameAnimation {
                running: window.visible
                onTriggered: drawer.time += frameTime
            }
        }

        // Stars settle on the corners once the panel has landed
        Repeater {
            model: [[0, 0, 9], [1, 0, 7], [1, 1, 9], [0, 1, 7], [0.5, 0, 4], [0, 0.42, 4], [1, 0.66, 4], [0.38, 1, 4]]

            Star {
                required property var modelData

                readonly property real inset: 7

                x: window.target.x + inset + (window.target.width - inset * 2) * modelData[0] - size
                y: window.target.y + inset + (window.target.height - inset * 2) * modelData[1] - size
                size: modelData[2]
                lit: true
                animated: false
                opacity: drawer.inkAmount
            }
        }

        // The content doesn't move with the shape, it's uncovered as the shape grows over it
        Item {
            x: window.shape.x
            y: window.shape.y
            width: window.shape.width
            height: window.shape.height
            clip: true
            opacity: window.clamp((window.progress - 0.6) / 0.4)

            Flickable {
                id: scroller

                x: window.target.x - window.shape.x + 22
                y: window.target.y - window.shape.y + 24
                width: window.target.width - 44
                height: window.target.height - 48
                contentHeight: page.item?.implicitHeight ?? 0
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                focus: true
                Keys.onEscapePressed: root.closeRequested()

                Loader {
                    id: page

                    width: scroller.width
                    active: window.visible
                    sourceComponent: root.content
                }
            }
        }
    }
}
