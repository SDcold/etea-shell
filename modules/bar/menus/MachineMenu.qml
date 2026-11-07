import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.modules.widgets
import qs.services

// What the rings in the bar are made of: every core, the heat, the memory and the swap,
// and the apps working hardest right now. Read again every two seconds while it's open.
ColumnLayout {
    id: root

    // The horizon climbs with the load
    readonly property color cardTint: Machine.cpu > 0.85 ? "#f0947c" : "#a6d8b8"
    readonly property real cardRise: 0.05 + Machine.cpu * 0.3

    property var memory: ({}) // MemTotal, MemAvailable, SwapTotal, SwapFree, in kB
    property var load: [] // the load averages over 1, 5 and 15 minutes
    property real uptime: 0 // seconds
    property var busiest: [] // { name, share }, the whole machine being 1

    function percent(share) {
        return Math.round(share * 100) + " %";
    }

    function since(seconds) {
        const days = Math.floor(seconds / 86400), hours = Math.floor(seconds % 86400 / 3600), minutes = Math.floor(seconds % 3600 / 60);
        if (days > 0)
            return Lang.t("{0} j {1} h", days, hours);
        return hours > 0 ? Lang.t("{0} h {1} min", hours, minutes) : Lang.t("{0} min", minutes);
    }

    spacing: 6
    width: 320

    // top's first look averages since boot, the second one is what's happening now
    Process {
        id: reader

        command: ["sh", "-c", "grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo; echo @; cat /proc/loadavg /proc/uptime; echo @; top -b -n 2 -d 0.5 -o %CPU -w 200 | awk '/^ *PID/ { frame++; next } frame == 2 && NF >= 12 { print $9, $NF }' | head -12"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [memoryPart, timePart, busyPart] = text.split("@\n").map(part => part.trim().split("\n"));
                const memory = {};
                for (const line of memoryPart) {
                    const [key, value] = line.split(/:\s+/);
                    memory[key] = parseInt(value);
                }
                root.memory = memory;
                root.load = (timePart[0] ?? "").split(" ").slice(0, 3).map(Number);
                root.uptime = parseFloat(timePart[1] ?? "0");

                // One app often runs as several processes, they count together
                const apps = {};
                for (const line of busyPart ?? []) {
                    const [share, name] = line.trim().split(" ");
                    if (name)
                        apps[name] = (apps[name] ?? 0) + parseFloat(share.replace(",", ".")) / 100 / Math.max(1, Machine.cores.length);
                }
                root.busiest = Object.keys(apps).map(name => ({ name: name, share: apps[name] })).filter(app => app.share >= 0.005).sort((a, b) => b.share - a.share).slice(0, 4);
            }
        }
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 2000
        onTriggered: reader.running = true
    }

    MenuTitle {
        text: Lang.t("Processeur")
    }

    // One star per core, the same sky as the desktop widget
    CoreConstellation {
        Layout.fillWidth: true
        Layout.preferredHeight: 84
        alive: true
        ink: Theme.text
    }

    MenuFact {
        Layout.fillWidth: true
        label: Lang.t("Utilisation")
        value: root.percent(Machine.cpu) + (Machine.temperature > 0 ? `  ·  ${Math.round(Machine.temperature)} °C` : "")
    }

    MenuFact {
        Layout.fillWidth: true
        visible: root.load.length === 3
        label: Lang.t("Charge moyenne")
        value: root.load.map(value => value.toFixed(2).replace(".", Qt.locale(Config.locale).decimalPoint)).join("  ·  ")
    }

    MenuFact {
        Layout.fillWidth: true
        visible: root.uptime > 0
        label: Lang.t("Allumé depuis")
        value: root.since(root.uptime)
    }

    MenuTitle {
        Layout.topMargin: 6
        text: Lang.t("Mémoire")
    }

    MenuFact {
        Layout.fillWidth: true
        visible: root.memory.MemTotal > 0
        label: Lang.t("Utilisée")
        value: Lang.t("{0} sur {1}", Machine.size(root.memory.MemTotal - root.memory.MemAvailable), Machine.size(root.memory.MemTotal))
    }

    MenuFact {
        Layout.fillWidth: true
        visible: root.memory.MemTotal > 0
        label: "Swap"
        value: root.memory.SwapTotal > 0 ? Lang.t("{0} sur {1}", Machine.size(root.memory.SwapTotal - root.memory.SwapFree), Machine.size(root.memory.SwapTotal)) : Lang.t("Aucun")
    }

    MenuTitle {
        Layout.topMargin: 6
        visible: root.busiest.length > 0
        text: Lang.t("Les plus occupés")
    }

    Repeater {
        model: root.busiest

        MenuFact {
            required property var modelData

            Layout.fillWidth: true
            label: modelData.name
            value: root.percent(modelData.share)
        }
    }
}
