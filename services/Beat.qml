pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What the music looks like right now, thanks to cava. It only listens while
// something on screen actually wants to dance.
Singleton {
    id: root

    property int listeners: 0
    property var levels: []

    function join() {
        listeners += 1;
    }

    function leave() {
        listeners = Math.max(0, listeners - 1);
        if (!listeners)
            levels = [];
    }

    Process {
        running: root.listeners > 0
        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]
        stdout: SplitParser {
            onRead: line => root.levels = line.split(";").filter(value => value !== "").map(value => Number(value) / 100)
        }
    }
}
