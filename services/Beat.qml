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
    property var levels: [] // exactly what cava hears
    property var shown: [] // what we actually draw: quick to rise, slow to settle

    readonly property bool dancing: Config.groundMusic !== "off" && Planet.pageEmpty && Mpris.players.values.some(player => player.isPlaying)
    readonly property bool wanted: listeners > 0 || dancing

    onWantedChanged: {
        cava.running = wanted;
        if (!wanted)
            levels = [];
    }

    function join() {
        listeners += 1;
    }

    function leave() {
        listeners = Math.max(0, listeners - 1);
    }

    // Sound jumps around, but nothing on screen should. When the music stops,
    // everything sinks back down slowly, like a breath being let out.
    // Stepped on every frame the screen draws, so bars glide instead of jumping. The speeds
    // are per 25 ms and get scaled to however long the frame actually took.
    FrameAnimation {
        running: root.wanted || root.shown.length > 0
        onTriggered: {
            const count = Math.max(root.levels.length, root.shown.length);
            const steps = Math.min(frameTime, 0.1) / 0.025;
            const next = [];
            let highest = 0;
            for (let i = 0; i < count; i++) {
                const target = root.levels[i] ?? 0, now = root.shown[i] ?? 0;
                const speed = target > now ? 0.45 : root.wanted ? 0.2 : Theme.groundSettle;
                const value = now + (target - now) * (1 - Math.pow(1 - speed, steps));
                next.push(value);
                highest = Math.max(highest, value);
            }
            root.shown = !root.wanted && highest < 0.004 ? [] : next;
        }
    }

    // qs ipc call beat state, to check the music is really flowing
    IpcHandler {
        target: "beat"

        function state(): string {
            return `wanted ${root.wanted}, dancing ${root.dancing}, heard ${root.levels.length}, shown ${root.shown.length}, peak ${Math.max(0, ...root.shown).toFixed(3)}`;
        }

        function hold(on: bool): void {
            on ? root.join() : root.leave();
        }
    }

    // cava can quit on its own, when the audio device changes for instance. Bring it back.
    Timer {
        id: revive

        interval: 1000
        onTriggered: cava.running = root.wanted
    }

    Process {
        id: cava

        running: root.wanted
        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]
        onRunningChanged: {
            if (!running && root.wanted)
                revive.restart();
        }
        stdout: SplitParser {
            onRead: line => root.levels = line.split(";").filter(value => value !== "").map(value => Number(value) / 100)
        }
    }
}
