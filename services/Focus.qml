pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// A focus timer: work, then a break, then work again.
Singleton {
    id: root

    property string mode: "focus" // "focus" or "rest"
    readonly property int length: (mode === "focus" ? 25 : 5) * 60
    property int left: length
    property bool running: false
    readonly property real done: 1 - left / length

    function toggle() {
        running = !running;
    }

    function reset() {
        running = false;
        left = length;
    }

    function setMode(next) {
        mode = next;
        reset();
    }

    function clock() {
        return `${Math.floor(left / 60)}:${String(left % 60).padStart(2, "0")}`;
    }

    // When time's up, say so and get the next round ready
    function finish() {
        running = false;
        announcer.exec(["notify-send", "-a", Lang.t("Minuteur"), mode === "focus" ? Lang.t("Pause !") : Lang.t("On s'y remet"), mode === "focus" ? Lang.t("25 minutes de concentration, bravo. Prends 5 minutes.") : Lang.t("La pause est finie.")]);
        setMode(mode === "focus" ? "rest" : "focus");
    }

    Process {
        id: announcer
    }

    Timer {
        running: root.running
        repeat: true
        interval: 1000
        onTriggered: {
            root.left -= 1;
            if (root.left <= 0)
                root.finish();
        }
    }
}
