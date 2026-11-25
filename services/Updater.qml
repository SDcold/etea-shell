pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Keeps ETEA up to date from the git clone it runs from, through scripts/update.sh. It asks
// GitHub when Settings › About is open or you press the button, and quietly once a day, with
// a notification when there's something new. Once the new files land, it reloads the shell
// on the new version.
Singleton {
    id: root

    property string commit: ""
    property string date: ""
    property string branch: ""

    // "idle", "checking", "current", "available", "behindMain", "updating", "updated",
    // "offline", "unmanaged", "edited" or "diverged"
    property string state: "idle"
    property int behind: 0
    property var changes: [] // titles of the commits waiting
    property string mainLine: "" // on a branch of its own, the main line it's behind, like "main"

    readonly property bool busy: state === "checking" || state === "updating"

    function refresh() {
        info.running = true;
    }

    function check() {
        if (busy)
            return;
        state = "checking";
        checker.running = true;
    }

    // Once a day, unless Settings say not to: the check, and a word when there's news
    property bool daily: false
    property var memory: ({ checkedAt: 0, told: "" })

    function dailyCheck() {
        if (!Config.updateNotify || busy || state === "unmanaged" || Date.now() - (memory.checkedAt ?? 0) < 24 * 3600 * 1000)
            return;
        daily = true;
        check();
    }

    function remember(changes) {
        memory = Object.assign({}, memory, changes);
        notes.setText(JSON.stringify(memory));
    }

    // Each set of news is told once: a notification that offers to update right away
    function tell() {
        const key = `${mainLine}:${behind}:${changes[0] ?? ""}`;
        if (memory.told === key)
            return;
        remember({ told: key });
        const summary = mainLine ? Lang.t("{0} a avancé", mainLine) : Lang.t("ETEA a du nouveau");
        const count = behind === 1 ? Lang.t("Une nouveauté t'attend") : Lang.t("{0} nouveautés t'attendent", behind);
        const body = [count].concat(changes.slice(0, 3).map(change => `· ${change}`)).join("\n");
        teller.command = ["notify-send", "-a", "ETEA", "-i", Quickshell.shellPath("assets/logo.png"), "-A", `update=${Lang.t("Mettre à jour")}`, "-A", `later=${Lang.t("Plus tard")}`, summary, body];
        teller.fallback = [summary, body];
        teller.running = true;
    }

    // Up to date with its own branch, or moved up to the main line it's behind
    function update() {
        if (busy)
            return;
        applier.command = ["bash", Quickshell.shellPath("scripts/update.sh"), state === "behindMain" ? "catchup" : "apply"];
        state = "updating";
        applier.running = true;
    }

    // What an exit code from the script means, when it isn't good news
    function trouble(code) {
        return { 2: "offline", 3: "unmanaged", 4: "edited", 5: "diverged" }[code] ?? "offline";
    }

    Process {
        id: info

        command: ["bash", Quickshell.shellPath("scripts/update.sh"), "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const [commit, date, branch] = text.trim().split("|");
                root.commit = commit ?? "";
                root.date = date ?? "";
                root.branch = branch ?? "";
            }
        }
        onExited: code => {
            if (code === 3)
                root.state = "unmanaged";
        }
    }

    Process {
        id: checker

        command: ["bash", Quickshell.shellPath("scripts/update.sh"), "check"]
        stdout: StdioCollector {
            id: news
        }
        onExited: code => {
            if (code !== 0) {
                root.state = root.trouble(code);
                root.daily = false;
                return;
            }
            // Its own branch first; then, after "@ main", what the main line has beyond it
            const [own, main] = news.text.trim().split(/^@ /m);
            const lines = (own ?? "").trim().split("\n");
            root.behind = Number(lines[0]) || 0;
            root.changes = lines.slice(1).filter(line => line !== "");
            root.mainLine = "";
            if (root.behind === 0 && main) {
                const rest = main.trim().split("\n");
                if (Number(rest[1]) > 0) {
                    root.mainLine = rest[0].trim();
                    root.behind = Number(rest[1]);
                    root.changes = rest.slice(2).filter(line => line !== "");
                }
            }
            root.state = root.behind === 0 ? "current" : root.mainLine ? "behindMain" : "available";
            root.remember({ checkedAt: Date.now() });
            if (root.daily && root.behind > 0)
                root.tell();
            root.daily = false;
        }
    }

    Process {
        id: applier

        command: ["bash", Quickshell.shellPath("scripts/update.sh"), "apply"]
        stdout: StdioCollector {
            id: applied
        }
        onExited: code => {
            if (code !== 0) {
                root.state = root.trouble(code);
                return;
            }
            root.behind = 0;
            root.changes = [];
            root.state = "updated";
            // New shaders: Qt keeps the old ones for as long as the process lives, so the shell
            // is started again, from outside it, instead of reloaded
            if (applied.text.includes("restart")) {
                const shell = Quickshell.shellPath("").replace(/\/$/, "");
                Quickshell.execDetached(["sh", "-c", 'sleep 0.5; qs kill -p "$1" >/dev/null 2>&1; sleep 1; setsid -f qs -p "$1" >/dev/null 2>&1', "sh", shell]);
                return;
            }
            // Quickshell reloads on its own as files change, but that can land halfway through
            // the merge, before a new folder is there, and leave the old version running.
            // Everything is in place now, so reload once more.
            Quickshell.reload(false);
        }
    }

    // qs ipc call update check | apply | state, for a script of your own
    IpcHandler {
        target: "update"

        function check(): void {
            root.check();
        }

        function apply(): void {
            root.update();
        }

        function state(): string {
            return `${root.state}, ${root.behind} behind, at ${root.commit} on ${root.branch}`;
        }
    }

    // The answer to the notification: its button, or nothing if it was let go
    Process {
        id: teller

        property var fallback: []

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "update")
                    root.update();
            }
        }
        // Without notify-send, the shell says it itself, without the button
        onExited: code => {
            if (code === 127)
                Notifs.say("ETEA", teller.fallback[0], teller.fallback[1]);
        }
    }

    // A few minutes after start, then every hour, it sees whether a day has gone by
    Timer {
        interval: 3 * 60 * 1000
        running: true
        onTriggered: root.dailyCheck()
    }

    Timer {
        interval: 3600 * 1000
        running: true
        repeat: true
        onTriggered: root.dailyCheck()
    }

    FileView {
        id: notes

        path: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/etea/updates.json`
        printErrors: false
        onLoaded: {
            try {
                root.memory = Object.assign({ checkedAt: 0, told: "" }, JSON.parse(text()));
            } catch (failure) {}
        }
    }
}
