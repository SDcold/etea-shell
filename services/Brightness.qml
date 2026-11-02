pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How bright the screen is, and a way to change it.
Singleton {
    id: root

    property real value: 0

    function set(level) {
        value = Math.max(0.02, Math.min(1, level));
        writer.exec(["brightnessctl", "s", `${Math.round(value * 100)}%`]);
    }

    function refresh() {
        reader.running = true;
    }

    Process {
        id: writer
    }

    Process {
        id: reader

        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const percent = text.split(",")[3];
                if (percent)
                    root.value = parseInt(percent) / 100;
            }
        }
    }

    Component.onCompleted: refresh()
}
