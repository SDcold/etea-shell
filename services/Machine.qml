pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How hard the computer is working, core by core, how warm it runs, and how fast data
// comes in and goes out. A quick look every couple of seconds is plenty.
Singleton {
    id: root

    property real cpu: 0
    property var cores: [] // each core's load, 0 to 1
    property real memory: 0
    property real temperature: 0 // °C, 0 when no sensor says
    property real download: 0 // bytes per second
    property real upload: 0
    property var last: null
    property var lastCores: []
    property var lastNet: null

    // Busy time and total time of one "cpu" line of /proc/stat
    function times(line) {
        const values = line.trim().split(/\s+/).slice(1).map(Number);
        return { idle: values[3] + values[4], total: values.reduce((sum, value) => sum + value, 0) };
    }

    function load(now, before) {
        return before && now.total > before.total ? 1 - (now.idle - before.idle) / (now.total - before.total) : 0;
    }

    Process {
        id: reader

        command: ["sh", "-c", "grep '^cpu' /proc/stat; echo @; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; echo @; tail -n +3 /proc/net/dev; echo @; for zone in /sys/class/thermal/thermal_zone*; do echo \"$(cat \"$zone/type\") $(cat \"$zone/temp\")\"; done 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [cpuPart, memoryPart, netPart, heatPart] = text.split("@\n").map(part => part.trim().split("\n"));

                const all = root.times(cpuPart[0]);
                root.cpu = root.load(all, root.last) || root.cpu;
                root.last = all;
                const each = cpuPart.slice(1).map(root.times);
                if (root.lastCores.length === each.length)
                    root.cores = each.map((now, i) => root.load(now, root.lastCores[i]));
                root.lastCores = each;

                const value = line => Number(line.split(/\s+/)[1]);
                root.memory = 1 - value(memoryPart[1]) / value(memoryPart[0]);

                // Every interface but the loopback, added up
                let received = 0, sent = 0;
                for (const line of netPart) {
                    const [name, counters] = line.trim().split(":");
                    if (!counters || name.trim() === "lo")
                        continue;
                    const fields = counters.trim().split(/\s+/).map(Number);
                    received += fields[0];
                    sent += fields[8];
                }
                const now = Date.now();
                if (root.lastNet && now > root.lastNet.time) {
                    const seconds = (now - root.lastNet.time) / 1000;
                    root.download = Math.max(0, received - root.lastNet.received) / seconds;
                    root.upload = Math.max(0, sent - root.lastNet.sent) / seconds;
                }
                root.lastNet = { received: received, sent: sent, time: now };

                // The processor package if it's there, else anything that sounds like a CPU
                const zones = (heatPart ?? []).map(line => line.split(" ")).filter(zone => zone.length === 2);
                const zone = zones.find(zone => zone[0] === "x86_pkg_temp") ?? zones.find(zone => /cpu|pkg|k10temp|soc/i.test(zone[0])) ?? zones[0];
                root.temperature = zone ? Number(zone[1]) / 1000 : 0;
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
}
