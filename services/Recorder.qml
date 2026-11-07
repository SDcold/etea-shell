pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

// Films a piece of the screen with wf-recorder, into Videos/Captures. The bar shows it's
// rolling and stops it with a click, the capture shortcut stops it too.
Singleton {
    id: root

    readonly property bool recording: film.running
    property real startedAt: 0
    property string file: ""
    property int seconds: 0
    property string missing: "" // the tool that kept the film from starting

    function start(geometry, withSound) {
        if (recording)
            return;
        // What you hear, not your microphone: the default output's monitor
        film.command = ["sh", "-c", `command -v wf-recorder >/dev/null || { echo "missing wf-recorder"; exit 1; }; dir="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Captures"; mkdir -p "$dir"; file="$dir/etea-$(date +%Y%m%d-%H%M%S).mp4"; echo "$file"; exec wf-recorder -y -g "$1" ${withSound ? '--audio="$(pactl get-default-sink).monitor"' : ""} -f "$file" >/dev/null 2>&1`, "sh", geometry];
        file = "";
        missing = "";
        seconds = 0;
        startedAt = Date.now();
        film.running = true;
    }

    // wf-recorder finishes the file properly on SIGINT
    function stop() {
        if (recording)
            film.signal(2);
    }

    function elapsed(seconds) {
        return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
    }

    Process {
        id: film

        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("missing "))
                    root.missing = line.slice(8).trim();
                else if (!root.file)
                    root.file = line.trim();
            }
        }
        onExited: {
            if (root.missing)
                root.tell(root.missing);
            else if (root.file)
                Notifs.say(Lang.t("Capture"), Lang.t("Vidéo enregistrée"), root.file);
        }
    }

    function tell(tool) {
        Notifs.say(Lang.t("Capture"), Lang.t("Capture impossible"), Lang.t("Il manque {0}. Installe-le, puis réessaie.", tool));
    }

    // A zone drawn with slurp, for the shortcuts that film without the capture overlay
    Process {
        id: zone

        property bool sound: false

        command: ["sh", "-c", 'command -v slurp >/dev/null && exec slurp || echo "missing slurp"']
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.startsWith("missing "))
                    root.tell("slurp");
                else if (text.trim())
                    root.start(text.trim(), zone.sound);
            }
        }
    }

    // qs ipc call recorder start "0,0 1920x1080" false, then stop
    IpcHandler {
        target: "recorder"

        function start(geometry: string, withSound: bool): void {
            root.start(geometry, withSound);
        }

        function stop(): void {
            root.stop();
        }

        // One key to start and stop: a zone you draw, or the whole focused screen
        function region(withSound: bool): void {
            if (root.recording) {
                root.stop();
                return;
            }
            zone.sound = withSound;
            zone.running = true;
        }

        function screen(withSound: bool): void {
            if (root.recording) {
                root.stop();
                return;
            }
            const output = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
            root.start(`${output.x},${output.y} ${output.width}x${output.height}`, withSound);
        }

        function state(): string {
            return root.recording ? `recording ${root.elapsed(root.seconds)} into ${root.file}` : "idle";
        }
    }

    Timer {
        running: root.recording
        repeat: true
        interval: 1000
        onTriggered: root.seconds = Math.round((Date.now() - root.startedAt) / 1000)
    }
}
