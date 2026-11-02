pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The words of the song playing, in time with it, for the karaoke widget. They come from
// LRCLIB through scripts/lyrics.sh, only while the widget is out, and are cached.
Singleton {
    id: root

    readonly property var player: Music.player
    readonly property bool wanted: Desk.shown.includes("lyrics") && player !== null
    readonly property string song: player ? `${player.trackArtist ?? ""}\n${player.trackTitle ?? ""}` : ""

    property var lines: [] // { time, text }, in order
    property string lookup: "idle" // "loading", "found", "none" or "offline"
    property real now: 0 // where the song is, in seconds, smooth between the player's updates

    // The line being sung: the last one that has started, a hair early so the eye keeps up
    readonly property int index: {
        let found = -1;
        for (let i = 0; i < lines.length && lines[i].time <= now + 0.15; i++)
            found = i;
        return found;
    }
    readonly property real progress: {
        if (index < 0)
            return 0;
        const start = lines[index].time, end = lines[index + 1]?.time ?? start + 4;
        return Math.max(0, Math.min(1, (now - start) / Math.max(0.1, end - start)));
    }

    function line(offset) {
        return lines[index + offset]?.text ?? "";
    }

    // "[01:23.45] words", sometimes with several times for one line
    function parse(text) {
        const found = [];
        for (const raw of text.split("\n")) {
            const words = raw.replace(/\[[^\]]*\]/g, "").trim();
            const stamp = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
            let time;
            while ((time = stamp.exec(raw)) !== null)
                found.push({ time: Number(time[1]) * 60 + Number(time[2]), text: words });
        }
        return found.sort((a, b) => a.time - b.time);
    }

    property string asked: "" // the song the running search is for
    property bool again: false // the song changed while searching, search once more after

    function fetch() {
        lines = [];
        if (!wanted || !player.trackTitle)
            return;
        lookup = "loading";
        if (finder.running) {
            again = true;
            return;
        }
        asked = song;
        finder.command = ["bash", Quickshell.shellPath("scripts/lyrics.sh"), player.trackArtist ?? "", player.trackTitle ?? "", player.trackAlbum ?? "", String(Math.round(player.length || 0))];
        finder.running = true;
    }

    onSongChanged: {
        anchor();
        fetch();
    }
    onWantedChanged: fetch()

    Process {
        id: finder

        stdout: StdioCollector {
            id: answer
        }
        onExited: code => {
            // An answer for a song that's gone by now is no answer
            if (root.again || root.asked !== root.song) {
                root.again = false;
                root.fetch();
                return;
            }
            if (code === 0) {
                root.lines = root.parse(answer.text);
                root.lookup = root.lines.length ? "found" : "none";
            } else if (code === 1) {
                root.lookup = "none";
            } else {
                root.lookup = "offline";
                retry.restart();
            }
        }
    }

    // LRCLIB was busy or out of reach: ask again in a little while
    Timer {
        id: retry

        interval: 30000
        onTriggered: {
            if (root.lookup === "offline")
                root.fetch();
        }
    }

    // The player tells us where it is now and then; in between, we count ourselves
    property real anchorPosition: 0
    property real anchorTime: 0

    function anchor() {
        anchorPosition = player?.position ?? 0;
        anchorTime = Date.now();
        now = anchorPosition;
    }

    Connections {
        target: root.player

        function onPositionChanged() {
            root.anchor();
        }

        function onIsPlayingChanged() {
            root.anchor();
        }
    }

    FrameAnimation {
        running: root.wanted && root.lookup === "found" && (root.player?.isPlaying ?? false) && Planet.pageEmpty
        onTriggered: root.now = root.anchorPosition + (Date.now() - root.anchorTime) / 1000 * (root.player?.rate || 1)
    }
}
