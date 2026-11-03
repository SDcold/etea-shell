import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.bar
import qs.services

// The song's words in a porthole lit by your world, with a touch of the cover, karaoke
// style: the sung line takes the light and a star rides the thread under it.
Item {
    id: root

    property var options: ({})
    property real enter: 0

    readonly property bool singing: Lyrics.lookup === "found"
    readonly property string waiting: {
        if (!Music.player)
            return Lang.t("Les paroles apparaîtront ici.");
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

    implicitWidth: 580
    implicitHeight: 176

    ContentTint {
        id: colour

        image: Music.player?.trackArtUrl ?? ""
        name: Music.player?.trackTitle ?? "etea"
    }

    HandCard {
        anchors.fill: parent
        seed: "lyrics"
        // Your world's light, with a touch of the cover in it
        tint: Music.player ? Qt.tint(Theme.windowLit, Qt.alpha(colour.color, 0.35)) : Theme.windowLit
        rise: 0.05
        alive: Planet.pageEmpty
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

    ColumnLayout {
        visible: root.singing
        anchors.centerIn: parent
        width: parent.width - 48
        spacing: 8

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Lyrics.line(-1)
            elide: Text.ElideRight
            color: Qt.alpha(Theme.text, 0.45)
            font.family: Theme.font
            font.pixelSize: 13
        }

        KaraokeLine {
            Layout.fillWidth: true
            text: Lyrics.line(0)
            resting: Lyrics.index < 0 || Lyrics.line(0) === ""
            progress: Lyrics.progress
            size: 24
            opacity: 1 - root.enter * 0.7

            transform: Translate {
                y: root.enter * 10
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Lyrics.line(1)
            elide: Text.ElideRight
            color: Qt.alpha(Theme.text, 0.65)
            font.family: Theme.font
            font.pixelSize: 14
        }
    }

    Text {
        visible: !root.singing
        anchors.centerIn: parent
        width: parent.width - 48
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.waiting
        color: Qt.alpha(Theme.text, 0.7)
        font.family: Theme.font
        font.pixelSize: 15
    }
}
