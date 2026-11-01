import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.modules.bar
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

        Item {
            id: card

            readonly property real wanted: Menus.anchorX - width / 2

            x: Math.max(14, Math.min(parent.width - width - 14, wanted))
            y: 8
            width: menu.width + 40
            height: menu.height + 40

            HandCard {
                anchors.fill: parent
                seed: Menus.open
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
