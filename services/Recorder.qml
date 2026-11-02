pragma Singleton

import QtQuick
import Quickshell
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

    function start(geometry, withSound) {
        if (recording)
            return;
        // What you hear, not your microphone: the default output's monitor
        film.command = ["sh", "-c", `dir="$(xdg-user-dir VIDEOS)/Captures"; mkdir -p "$dir"; file="$dir/etea-$(date +%Y%m%d-%H%M%S).mp4"; echo "$file"; exec wf-recorder -y -g "$1" ${withSound ? '--audio="$(pactl get-default-sink).monitor"' : ""} -f "$file" >/dev/null 2>&1`, "sh", geometry];
        file = "";
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
                if (!root.file)
                    root.file = line.trim();
            }
        }
        onExited: {
            if (root.file)
                say.exec(["notify-send", "-a", Lang.t("Capture"), Lang.t("Vidéo enregistrée"), root.file]);
        }
    }

    Process {
        id: say
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
