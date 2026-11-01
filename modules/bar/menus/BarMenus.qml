import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.modules.stage
import qs.services

// The menus hanging under the bar. One at a time, and clicking away closes it.
Scope {
    IpcHandler {
        target: "bar"

        function open(name: string, x: real): void {
            Menus.toggle(name, x);
        }
    }

    PanelWindow {
        id: panel

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: Menus.open !== ""
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitHeight: 640
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "etea:menu"
        WlrLayershell.keyboardFocus: Menus.open === "network" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        margins.top: Theme.barGap + Theme.barHeight + 6

        anchors {
            top: true
            left: true
            right: true
        }

        mask: Region {
            item: card
        }

        HyprlandFocusGrab {
            windows: [panel]
            active: Menus.open !== ""
            onCleared: Menus.close()
        }

        property real reveal: 0

        // Menus open through the same star as everything else, from under what you clicked
        NumberAnimation {
            id: unfold

            target: panel
            property: "reveal"
            from: 0
            to: 1
            duration: Theme.cardOpen
            easing.type: Easing.OutCubic
        }

        Connections {
            target: Menus

            function onOpenChanged() {
                if (Menus.open)
                    unfold.restart();
            }
        }

        Item {
            id: card

            readonly property real wanted: Menus.anchorX - width / 2

            x: Math.max(14, Math.min(parent.width - width - 14, wanted))
            y: 8
            width: menu.width + 40
            height: menu.height + 62
            layer.enabled: panel.reveal < 1
            layer.effect: StarMask {
                center: Qt.point(Menus.anchorX - card.x, 0)
                reach: fullReach * panel.reveal
                shine: (1 - panel.reveal) * 0.9
                tint: Menus.tint
            }

            HandCard {
                anchors.fill: parent
                seed: Menus.open
                tint: Menus.tint
                rise: menu.item?.cardRise ?? 0.08
            }

            Binding {
                target: Menus
                property: "tint"
                value: menu.item?.cardTint ?? Theme.windowLit
            }

            Loader {
                id: menu

                x: 20
                y: 20
                source: ({
                        calendar: "CalendarMenu.qml",
                        media: "MediaMenu.qml",
                        sound: "SoundMenu.qml",
                        network: "NetworkMenu.qml",
                        bluetooth: "BluetoothMenu.qml",
                        power: "PowerMenu.qml"
                    })[Menus.open] ?? ""
            }
        }
    }
}
