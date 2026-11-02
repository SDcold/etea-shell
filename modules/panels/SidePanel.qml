import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.modules.stage
import qs.services

// A side panel, opened like the bar menus: the card unfolds through a star from its top
// corner, and folds back into it when it closes.
Scope {
    id: root

    required property string side // "left" or "right"
    required property bool open
    property color tint: Theme.windowLit
    property Component content

    signal closeRequested()

    PanelWindow {
        id: window

        property real reveal: 0

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: root.open || reveal > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: Theme.panelWidth + Theme.barSide
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: `etea:panel-${root.side}`
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        margins.top: Theme.barOnTop ? Theme.barReserve + 6 : 6
        margins.bottom: Theme.barOnTop ? 0 : Theme.barReserve

        anchors {
            top: true
            bottom: true
            left: root.side === "left"
            right: root.side === "right"
        }

        mask: Region {
            item: card
        }

        HyprlandFocusGrab {
            windows: [window]
            active: root.open
            onCleared: root.closeRequested()
        }

        NumberAnimation {
            id: unfold

            target: window
            property: "reveal"
            to: 1
            duration: Theme.cardOpen
            easing.type: Easing.OutCubic
        }

        // Closing is the same star, folding back into the corner
        NumberAnimation {
            id: fold

            target: window
            property: "reveal"
            to: 0
            // The star covers the whole card for a while, so it has to start shrinking right away
            duration: Theme.cardOpen * 0.8
            easing.type: Easing.OutQuad
        }

        Connections {
            target: root

            function onOpenChanged() {
                (root.open ? fold : unfold).stop();
                (root.open ? unfold : fold).restart();
            }
        }

        Item {
            id: card

            x: root.side === "left" ? Theme.barSide : 0
            y: 8
            width: Theme.panelWidth
            height: parent.height - y - 14
            layer.enabled: window.reveal < 1
            layer.effect: StarMask {
                center: Qt.point(root.side === "left" ? 0 : card.width, Theme.barOnTop ? 0 : card.height)
                reach: fullReach * window.reveal
                shine: (1 - window.reveal) * 0.9
                tint: root.tint
            }

            HandCard {
                anchors.fill: parent
                seed: `panel-${root.side}`
                tint: root.tint
                rise: 0.06
                radius: 26
            }

            Flickable {
                id: scroller

                x: 22
                y: 24
                width: parent.width - 44
                height: parent.height - 48
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
