pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How hard the computer is working. A quick look every couple of seconds is plenty.
Singleton {
    id: root

    property real cpu: 0
    property real memory: 0
    property var last: null

    Process {
        id: reader

        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
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
            }
        }
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 2500
        onTriggered: reader.running = true
    }
}
