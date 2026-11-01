import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.config
import qs.modules.bar

// What's playing, with its cover. It only shows up when there's something to show.
Item {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    visible: player !== null && (player.trackTitle ?? "") !== ""
    implicitWidth: 340
    implicitHeight: 112

    HandCard {
        anchors.fill: parent
        seed: "media"
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Image {
            visible: status === Image.Ready
            Layout.preferredWidth: 76
            Layout.preferredHeight: 76
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(152, 152)
            source: root.player?.trackArtUrl ?? ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.player?.trackTitle ?? ""
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 17
            }

            Text {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                elide: Text.ElideRight
                color: Qt.alpha(Theme.text, 0.65)
                font.family: Theme.font
                font.pixelSize: 14
            }
        }
    }
}
