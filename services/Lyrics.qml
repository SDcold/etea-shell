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
        ask();
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

    function guess() {
        return anchorPosition + (Date.now() - anchorTime) / 1000 * (player?.isPlaying ? player.rate || 1 : 0);
    }

    // Quickshell reads the position once and counts on from there, so a player slow to get
    // going leaves it ahead for the whole song. Words sung need better: we ask the player.
    function ask() {
        if (!player?.dbusName || clock.running)
            return;
        clock.command = ["bash", "-c", 'echo $EPOCHREALTIME; busctl --user get-property "$1" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player Position; echo $EPOCHREALTIME', "-", player.dbusName];
        clock.running = true;
    }

    Process {
        id: clock

        stdout: StdioCollector {
            id: told
        }
        // The position, with the moments just before and after it was read: hearing the
        // process end comes much later, and never twice the same
        onExited: code => {
            // In a French session the seconds come with a comma
            const [before, reading, after] = told.text.trim().replace(/,/g, ".").split("\n");
            const micro = Number(reading?.split(" ")[1]);
            if (code !== 0 || !isFinite(micro) || !after)
                return;
            root.anchorPosition = micro / 1e6;
            root.anchorTime = (Number(before) + Number(after)) * 500;
            if (!root.player?.isPlaying)
                root.now = root.anchorPosition;
        }
    }

    Connections {
        target: root.player

        // Only a jump means something: a seek. The rest is Quickshell's own count.
        function onPositionChanged() {
            if (Math.abs(root.player.position - root.guess()) > 1.5) {
                root.anchor();
                root.ask();
            }
        }

        function onIsPlayingChanged() {
            root.anchor();
            root.ask();
        }
    }

    readonly property bool singing: wanted && lookup === "found" && (player?.isPlaying ?? false)

    Timer {
        running: root.singing
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.ask()
    }

    // Smooth on an empty page; behind windows, a step a second is plenty
    FrameAnimation {
        running: root.singing && Planet.pageEmpty
        onTriggered: root.now = root.guess()
    }

    Timer {
        running: root.singing && !Planet.pageEmpty
        interval: 1000
        repeat: true
        onTriggered: root.now = root.guess()
    }
}
