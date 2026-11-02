pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Keeps the screen awake: no dimming, no lock, no sleep while it's on. Each bar holds
// the inhibitor, since Wayland ties it to a window that stays on screen.
Singleton {
    id: root

    property bool on: false

    // qs ipc call wake toggle, for a shortcut of your own
    IpcHandler {
        target: "wake"

        function toggle(): bool {
            root.on = !root.on;
            return root.on;
        }
    }
}
