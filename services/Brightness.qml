pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How bright the screen is, and a way to change it. The backlight never goes all the way
// out: below its lowest step, the keys keep dimming through hyprsunset's gamma instead.
Singleton {
    id: root

    property real value: 0
    property bool known: false // the first reading is in, so changes from now on are real
    property string device: ""

    readonly property real floor: 0.02
    readonly property real step: 0.05
    readonly property real darkest: 0.25 // the lowest gamma, any darker and nothing reads
    property real dim: 1 // hyprsunset's gamma, 1 when it isn't dimming anything
    readonly property bool canDim: !Compositor.niri && NightLight.available

    // -n keeps at least one raw step lit, on panels where 2% rounds down to nothing
    function set(level) {
        value = Math.max(floor, Math.min(1, level));
        writer.exec(["brightnessctl", "-n", "s", `${Math.round(value * 100)}%`]);
        // Picking a brightness by hand lifts the extra dimming
        if (dim < 1)
            setDim(1);
    }

    // The keys: the gamma comes back first, then the backlight climbs
    function up() {
        if (dim < 1)
            setDim(dim + step);
        else
            set(value + step);
    }

    function down() {
        if (value > floor + 0.001 || !canDim)
            set(value - step);
        else
            setDim(dim - step);
    }

    // A hyprsunset that isn't running yet is started with no colour change, then given a
    // moment to open its socket
    function setDim(level) {
        if (!canDim)
            return;
        dim = Math.round(Math.max(darkest, Math.min(1, level)) * 100) / 100;
        const gamma = String(Math.round(dim * 100));
        dimmer.exec(["sh", "-c", `if pidof -q hyprsunset; then
            for i in 1 2 3 4 5 6 7 8 9 10; do hyprctl hyprsunset gamma ${gamma} >/dev/null && break; sleep 0.1; done
        else setsid -f hyprsunset -i -g ${gamma} >/dev/null 2>&1; fi`]);
        NightLight.running = true;
    }

    function refresh() {
        current.reload();
    }

    Process {
        id: writer
    }

    Process {
        id: dimmer
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

    // The gamma left from before a restart, or reset by a hyprsunset that went away
    Process {
        id: gammaReader

        command: ["hyprctl", "hyprsunset", "gamma"]
        stdout: StdioCollector {
            onStreamFinished: {
                const gamma = parseInt(text);
                root.dim = isNaN(gamma) ? 1 : Math.min(1, gamma / 100);
            }
        }
    }

    Timer {
        running: root.canDim
        repeat: true
        triggeredOnStart: true
        interval: 30000
        onTriggered: gammaReader.running = true
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.up();
        }

        function down(): void {
            root.down();
        }
    }
}
