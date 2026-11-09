import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// How far along the track is. Click or drag anywhere to jump there.
ColumnLayout {
    id: root

    property color tint: Theme.windowLit
    property color ink: Theme.text // the times under it
    property bool entering: true // false on the desktop, where it's simply there
    readonly property var player: Music.player
    readonly property bool known: (player?.lengthSupported ?? false) && player.length > 0

    spacing: 0
    visible: known

    MenuSlider {
        Layout.fillWidth: true
        tint: root.tint
        entering: root.entering
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
            color: Qt.alpha(root.ink, 0.7)
            font.family: Theme.font
            font.pixelSize: 10
        }

        Text {
            text: Music.clockTime(root.player?.length)
            color: Qt.alpha(root.ink, 0.7)
            font.family: Theme.font
            font.pixelSize: 10
        }
    }
}
