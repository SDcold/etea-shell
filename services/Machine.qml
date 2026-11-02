pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How hard the computer is working, and how fast data comes in and goes out.
// A quick look every couple of seconds is plenty.
Singleton {
    id: root

    property real cpu: 0
    property real memory: 0
    property real download: 0 // bytes per second
    property real upload: 0
    property var last: null
    property var lastNet: null

    Process {
        id: reader

        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; tail -n +3 /proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const times = lines[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = times[3] + times[4], total = times.reduce((sum, value) => sum + value, 0);
                if (root.last && total > root.last.total)
                    root.cpu = 1 - (idle - root.last.idle) / (total - root.last.total);
                root.last = { idle: idle, total: total };
                const value = line => Number(line.split(/\s+/)[1]);
                root.memory = 1 - value(lines[2]) / value(lines[1]);

                // Every interface but the loopback, added up
                let received = 0, sent = 0;
                for (const line of lines.slice(3)) {
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
