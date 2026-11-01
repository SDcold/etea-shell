pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config

// What the music looks like right now, thanks to cava. It only listens while something
// on screen actually wants to dance: the ground on an empty page, or a media card.
Singleton {
    id: root

    property int listeners: 0
    property var levels: []

    readonly property bool dancing: Config.groundDances && Planet.pageEmpty && Mpris.players.values.some(player => player.isPlaying)
    readonly property bool wanted: listeners > 0 || dancing

    onWantedChanged: {
        if (!wanted)
            levels = [];
    }

    function join() {
        listeners += 1;
    }

    function leave() {
        listeners = Math.max(0, listeners - 1);
    }

    Process {
        running: root.wanted
        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]
        stdout: SplitParser {
            onRead: line => root.levels = line.split(";").filter(value => value !== "").map(value => Number(value) / 100)
        }
    }
}
