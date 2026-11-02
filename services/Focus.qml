pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// A focus timer: work, then a break, then work again.
Singleton {
    id: root

    property string mode: "focus" // "focus" or "rest"
    readonly property int length: (mode === "focus" ? Config.focusMinutes : Config.restMinutes) * 60
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

    // A pair of lengths at once, like 25 and 5 or 50 and 10
    function usePreset(work, rest) {
        Config.focusMinutes = work;
        Config.restMinutes = rest;
        reset();
    }

    // A new length while stopped shows right away
    onLengthChanged: {
        if (!running)
            left = length;
    }

    function clock() {
        return `${Math.floor(left / 60)}:${String(left % 60).padStart(2, "0")}`;
    }

    // When time's up, say so and get the next round ready
    function finish() {
        running = false;
        announcer.exec(["notify-send", "-a", Lang.t("Minuteur"), mode === "focus" ? Lang.t("Pause !") : Lang.t("On s'y remet"), mode === "focus" ? Lang.t("{0} minutes de concentration, bravo. Prends-en {1}.", Config.focusMinutes, Config.restMinutes) : Lang.t("La pause est finie.")]);
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
