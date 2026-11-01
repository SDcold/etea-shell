import QtQuick
import qs.config
import qs.modules.bar
import qs.services

// Previous, play or pause, next. While the music plays, a star glows behind the button.
Row {
    id: root

    property color tint: Theme.windowLit
    readonly property var player: Music.player

    spacing: 28

    Repeater {
        model: [
            { icon: "skip-back", size: 24, allowed: root.player?.canGoPrevious ?? false, run: () => root.player.previous() },
            { icon: root.player?.isPlaying ? "pause" : "play", size: 30, main: true, allowed: root.player?.canTogglePlaying ?? false, run: () => root.player.togglePlaying() },
            { icon: "skip-forward", size: 24, allowed: root.player?.canGoNext ?? false, run: () => root.player.next() }
        ]

        Item {
            id: button

            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            opacity: modelData.allowed ? 1 : 0.35
            scale: pointer.pressed ? 0.82 : pointer.containsMouse ? 1.14 : 1

            Behavior on scale {
                NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
            }

            Star {
                visible: button.modelData.main ?? false
                anchors.centerIn: parent
                size: 25
                lit: root.player?.isPlaying ?? false
                animated: false
                opacity: root.player?.isPlaying ? 0.3 : 0.1
            }

            Icon {
                anchors.centerIn: parent
                name: button.modelData.icon
                size: button.modelData.size
            }

            MouseArea {
                id: pointer

                anchors.fill: parent
                anchors.margins: -5
                enabled: button.modelData.allowed
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: button.modelData.run()
            }
        }
    }
}
