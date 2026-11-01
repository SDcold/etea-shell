import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.config
import qs.modules.bar

// What's playing, with the controls that belong to it.
ColumnLayout {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    // The whole card takes on the colour of the cover
    readonly property color cardTint: colour.color
    readonly property real cardRise: 0.07

    spacing: 12
    width: 360

    ContentTint {
        id: colour

        image: root.player?.trackArtUrl ?? ""
        name: root.player?.trackTitle ?? "etea"
    }

    // Players don't announce every second, so we ask
    Timer {
        running: root.player?.isPlaying ?? false
        repeat: true
        interval: 1000
        onTriggered: root.player.positionChanged()
    }

    Text {
        visible: !root.player
        text: "Rien en cours de lecture."
        color: Qt.alpha(Theme.text, 0.7)
        font.family: Theme.font
        font.pixelSize: 16
    }

    RowLayout {
        visible: root.player !== null
        spacing: 14

        Image {
            visible: status === Image.Ready
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(168, 168)
            source: root.player?.trackArtUrl ?? ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.player?.trackTitle ?? ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 18
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

    StarWave {
        visible: root.player !== null
        Layout.fillWidth: true
        tint: colour.color
    }

    MenuSlider {
        visible: (root.player?.lengthSupported ?? false) && root.player.length > 0
        Layout.fillWidth: true
        value: root.player?.position ?? 0
        maximum: root.player?.length || 1
        onMoved: value => root.player.position = value
    }

    Row {
        visible: root.player !== null
        Layout.alignment: Qt.AlignHCenter
        spacing: 30

        Repeater {
            model: [
                { icon: "skip-back", run: () => root.player.previous() },
                { icon: root.player?.isPlaying ? "pause" : "play", run: () => root.player.togglePlaying() },
                { icon: "skip-forward", run: () => root.player.next() }
            ]

            Icon {
                required property var modelData

                name: modelData.icon
                size: 28

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onPressed: parent.modelData.run()
                }
            }
        }
    }
}
