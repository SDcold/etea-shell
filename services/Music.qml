pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The one player everything follows. A paused track stays the current one, so pausing
// doesn't send the bar and the widgets off to some other idle player.
Singleton {
    id: root

    property var remembered: null

    readonly property var player: {
        const players = Mpris.players.values.filter(p => (p.trackTitle ?? "") !== "");
        return players.find(p => p.isPlaying) ?? players.find(p => p === remembered) ?? players.find(p => p.playbackState === MprisPlaybackState.Paused) ?? players[0] ?? null;
    }

    onPlayerChanged: remembered = player

    function clockTime(seconds) {
        const total = Math.max(0, Math.floor(seconds || 0));
        const minutes = Math.floor(total / 60), rest = String(total % 60).padStart(2, "0");
        return minutes >= 60 ? `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, "0")}:${rest}` : `${minutes}:${rest}`;
    }

    // Players don't announce every second, so we ask
    Timer {
        running: root.player?.isPlaying ?? false
        repeat: true
        interval: 1000
        onTriggered: root.player.positionChanged()
    }
}
