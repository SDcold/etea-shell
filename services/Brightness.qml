pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How bright the screen is, and a way to change it.
Singleton {
    id: root

    property real value: 0
    property bool known: false // the first reading is in, so changes from now on are real
    property string device: ""

    function set(level) {
        value = Math.max(0.02, Math.min(1, level));
        writer.exec(["brightnessctl", "s", `${Math.round(value * 100)}%`]);
    }

    function refresh() {
        current.reload();
    }

    Process {
        id: writer
    }

    // The screen's backlight, found once
    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        id: highest

        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        blockLoading: true
    }

    FileView {
        id: current

        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: {
            const most = Number(highest.text());
            if (most > 0) {
                root.value = Number(text()) / most;
                root.known = true;
            }
        }
    }

    // The keys change it behind our back and nothing announces it, so we peek a few
    // times a second. Reading the file is cheap, starting a process each time wasn't.
    Timer {
        running: root.device !== ""
        repeat: true
        interval: 400
        onTriggered: current.reload()
    }
}
