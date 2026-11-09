import QtQuick
import qs.config
import qs.services

// The song's words written on the sky as it plays, karaoke style: the line being sung
// takes your world's light while a star rides the thread under it, the one before
// fades above, the next waits below.
Column {
    id: root

    property real sky: 1080
    property var options: ({})
    property real enter: 0 // 1 the moment a new line comes up, back to 0 as it settles

    readonly property bool singing: Lyrics.lookup === "found"
    readonly property bool playing: Music.player?.isPlaying ?? false
    property bool awake: playing // stays a moment after the music stops, so a gap between songs doesn't blink
    readonly property string waiting: {
        switch (Lyrics.lookup) {
        case "loading":
            return Lang.t("On cherche les paroles…");
        case "none":
            return Lang.t("Pas de paroles synchronisées pour ce titre.");
        case "offline":
            return Lang.t("Paroles hors de portée pour l'instant.");
        }
        return "";
    }

    width: sky
    spacing: sky * 0.012

    // Out of sight while nothing plays. Super still finds it, to move it or put it away.
    opacity: awake ? 1 : 0
    onPlayingChanged: {
        if (playing) {
            nap.stop();
            awake = true;
        } else {
            nap.restart();
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: Theme.normal }
    }

    Timer {
        id: nap

        interval: 1500
        onTriggered: root.awake = false
    }

    Connections {
        target: Lyrics

        function onIndexChanged() {
            rise.restart();
        }
    }

    NumberAnimation {
        id: rise

        target: root
        property: "enter"
        from: 1
        to: 0
        duration: 420
        easing.type: Easing.OutCubic
    }

    Text {
        visible: root.singing
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: Lyrics.line(-1)
        elide: Text.ElideRight
        color: Qt.alpha(Desk.ink, 0.3)
        font.family: Theme.font
        font.pixelSize: root.sky * 0.02
    }

    KaraokeLine {
        visible: root.singing
        width: parent.width
        // Between two lines, or before the first, three stars hold the place
        text: Lyrics.line(0)
        resting: Lyrics.index < 0 || Lyrics.line(0) === ""
        progress: Lyrics.progress
        ink: Desk.ink
        size: root.sky * 0.046
        opacity: 1 - root.enter * 0.7

        transform: Translate {
            y: root.enter * root.sky * 0.02
        }
    }

    Text {
        visible: root.singing
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: Lyrics.line(1)
        elide: Text.ElideRight
        color: Qt.alpha(Desk.ink, 0.5)
        font.family: Theme.font
        font.pixelSize: root.sky * 0.022
    }

    Text {
        visible: !root.singing
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.waiting
        color: Qt.alpha(Desk.ink, 0.6)
        font.family: Theme.font
        font.pixelSize: root.sky * 0.018
    }
}
