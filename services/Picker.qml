pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Picks a colour anywhere on screen and copies it, then says which one.
Singleton {
    id: root

    function pick() {
        picker.running = true;
    }

    Process {
        id: picker

        command: ["hyprpicker", "-a", "-f", "hex"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    announcer.exec(["notify-send", "-a", Lang.t("Pipette"), Lang.t("Couleur copiée"), text.trim()]);
            }
        }
    }

    Process {
        id: announcer
    }
}
