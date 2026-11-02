import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.services

// A side panel that pours out of whatever opened it, like a drop pulled out of the
// bar: it stretches sideways, falls into place, then lets go. Closing pours it back.
Scope {
    id: root

    required property string side // "left" or "right"
    required property bool open
    property rect anchorRect: Qt.rect(0, 0, 0, 0)
    property color tint: Theme.windowLit
    property Component content

    signal closeRequested()

    PanelWindow {
        id: window

        property real progress: root.open ? 1 : 0

        function clamp(value) {
            return Math.max(0, Math.min(1, value));
        }

        function lerp(from, to, amount) {
            return from + (to - from) * amount;
        }

        // Opened from the keyboard, the drop comes from roughly where the button would be
        readonly property rect from: root.anchorRect.width > 0 ? root.anchorRect : root.side === "right" ? Qt.rect(width - Theme.barSide - 44, Theme.barGap, 44, Theme.barHeight) : Qt.rect(width / 2 - 90, Theme.barGap, 180, Theme.barHeight)
        readonly property rect target: {
            const top = Theme.barGap + Theme.barHeight + 12;
            return Qt.rect(root.side === "right" ? width - Theme.barSide - Theme.panelWidth : Theme.barSide, top, Theme.panelWidth, height - top - 14);
        }

        // Sideways first with a little overshoot, then down, then the drop lets go
        readonly property real spread: {
            const t = clamp(progress / 0.7) - 1, c = 1.2;
            return 1 + (c + 1) * t * t * t + c * t * t;
        }
        // Closing isn't the opening played backwards: it rises steadily, then narrows into the button
        readonly property real drop: {
            const t = clamp((progress - 0.12) / 0.88);
            return root.open ? 1 - Math.pow(1 - t, 5) : t * t * (3 - 2 * t);
        }
        readonly property real letGo: 1 - clamp((progress - 0.55) / 0.4)
        readonly property rect shape: Qt.rect(lerp(from.x, target.x, spread), lerp(from.y, target.y, spread), lerp(from.width, target.width, spread), lerp(from.height, target.height, drop))

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
            property vector4d anchorBox: Qt.vector4d(window.from.x - x, window.from.y - y, window.from.width, window.from.height)
            property vector4d panelBox: Qt.vector4d(window.shape.x - x, window.shape.y - y, window.shape.width, window.shape.height)
            property vector2d resolution: Qt.vector2d(width, height)
            property real anchorRadius: window.from.height / 2
            property real panelRadius: window.lerp(window.from.height / 2, 26, window.spread)
            property real blend: 34
            property real anchorAmount: window.letGo
            property real time: 0
            property real seed: root.side === "right" ? 4.7 : 1.3
            property real rise: 0.06
            property real inkAmount: window.clamp((window.progress - 0.85) / 0.15)

            x: Math.min(window.shape.x, window.from.x) - pad
            y: Math.min(window.shape.y, window.from.y) - pad
            width: Math.max(window.shape.x + window.shape.width, window.from.x + window.from.width) - x + pad
            height: Math.max(window.shape.y + window.shape.height, window.from.y + window.from.height) - y + pad
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
