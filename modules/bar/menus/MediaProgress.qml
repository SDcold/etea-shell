import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// How far along the track is. Click or drag anywhere to jump there.
ColumnLayout {
    id: root

    property color tint: Theme.windowLit
    readonly property var player: Music.player
    readonly property bool known: (player?.lengthSupported ?? false) && player.length > 0

    spacing: 0
    visible: known

    MenuSlider {
        Layout.fillWidth: true
        tint: root.tint
        value: root.player?.position ?? 0
        maximum: root.player?.length || 1
        onMoved: value => {
            if (root.player?.canSeek)
                root.player.position = value;
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: Music.clockTime(root.player?.position)
            color: Qt.alpha(Theme.text, 0.7)
            font.family: Theme.font
            font.pixelSize: 12
        }

        Text {
            text: Music.clockTime(root.player?.length)
            color: Qt.alpha(Theme.text, 0.7)
            font.family: Theme.font
            font.pixelSize: 12
        }
    }
}
