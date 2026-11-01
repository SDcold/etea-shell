import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.config
import qs.modules.bar
import qs.services

// What's playing. The card takes on the colour of the cover and the music dances across it.
Item {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    visible: player !== null && (player.trackTitle ?? "") !== ""
    implicitWidth: 380
    implicitHeight: 164

    ContentTint {
        id: colour

        image: root.player?.trackArtUrl ?? ""
        name: root.player?.trackTitle ?? "etea"
    }

    HandCard {
        anchors.fill: parent
        seed: "media"
        tint: colour.color
        rise: 0.08
        alive: Planet.pageEmpty
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        ClippingRectangle {
            visible: cover.status === Image.Ready
            Layout.preferredWidth: 104
            Layout.preferredHeight: 104
            radius: 14
            color: "transparent"

            Image {
                id: cover

                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(208, 208)
                source: root.player?.trackArtUrl ?? ""
            }
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
                font.pixelSize: 19
            }

            Text {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                elide: Text.ElideRight
                color: Qt.alpha(Theme.text, 0.7)
                font.family: Theme.font
                font.pixelSize: 14
            }

            StarWave {
                Layout.fillWidth: true
                Layout.topMargin: 6
                tint: colour.color
                listening: Planet.pageEmpty && (root.player?.isPlaying ?? false)
            }
        }
    }
}
