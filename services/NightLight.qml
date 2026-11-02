pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The warm screen for the evening, through hyprsunset.
Singleton {
    id: root

    property bool available: false
    property int temperature: 6000
    readonly property bool on: temperature < 5800
    readonly property int warm: 4200

    function toggle() {
        writer.exec(["/usr/bin/hyprctl", "hyprsunset", ...(on ? ["identity"] : ["temperature", String(warm)])]);
        temperature = on ? 6500 : warm;
    }

    Process {
        id: writer
    }

    Process {
        id: reader

        command: ["/usr/bin/hyprctl", "hyprsunset", "temperature"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = parseInt(text);
                root.available = !isNaN(value);
                if (root.available)
                    root.temperature = value;
            }
        }
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 30000
        onTriggered: reader.running = true
    }
}
