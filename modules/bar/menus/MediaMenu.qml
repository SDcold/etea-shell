import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.config

// What's playing, with the controls that belong to it.
ColumnLayout {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    function glyph(code) {
        return String.fromCodePoint(code);
    }

    spacing: 12
    width: 340

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
            Layout.preferredWidth: 84
            Layout.preferredHeight: 84
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
                { code: 0xf04ae, run: () => root.player.previous() },
                { code: root.player?.isPlaying ? 0xf03e4 : 0xf040a, run: () => root.player.togglePlaying() },
                { code: 0xf04ad, run: () => root.player.next() }
            ]

            Text {
                required property var modelData

                text: root.glyph(modelData.code)
                color: Theme.text
                font.family: Theme.iconFont
                font.pixelSize: 24

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
