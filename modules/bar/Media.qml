import QtQuick
import Quickshell.Services.Mpris
import qs.config
import qs.services

// Whatever is playing right now. Click to pause or resume.
Text {
    id: root

    // Go for the player that's actually playing, or else the first one around
    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    visible: player !== null && (player.trackTitle ?? "") !== ""
    width: Math.min(implicitWidth, 300)
    anchors.verticalCenter: parent.verticalCenter
    elide: Text.ElideRight
    text: {
        if (!player)
            return "";
        const artist = player.trackArtist ?? "";
        return player.trackTitle + (artist ? " · " + artist : "");
    }
    color: Theme.textSoft
    opacity: player?.isPlaying ? 1 : 0.6
    font.family: Theme.font
    font.pixelSize: Theme.textSize

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton)
                root.player?.togglePlaying();
            else
                Menus.toggle("media", root.mapToItem(null, root.width / 2, 0).x);
        }
    }
}
