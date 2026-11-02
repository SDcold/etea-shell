import QtQuick
import QtQuick.Effects
import qs.config
import qs.services

// Whatever is playing right now: a note, then the title gliding by in a narrow window.
// Click for the player, right click to pause or resume.
Item {
    id: root

    // Go for the player that's actually playing, or else the first one around
    readonly property var player: Music.player
    readonly property bool wanted: player !== null && (player.trackTitle ?? "") !== ""
    readonly property real limit: Math.round(200 * Theme.barScale)

    implicitWidth: content.implicitWidth
    implicitHeight: Theme.barHeight
    opacity: player?.isPlaying ? 1 : 0.6

    Row {
        id: content

        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "music"
            size: Theme.iconSize - 3
            tint: Theme.textSoft
        }

        Item {
            id: view

            readonly property bool moving: Config.mediaTitle === "scroll" && title.implicitWidth > root.limit

            visible: Config.mediaTitle !== "off"
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(title.implicitWidth, root.limit)
            height: title.implicitHeight
            clip: true

            // Too long to fit: it slides by, twice in a row so it loops without a jump, and the
            // edges fade so the words come out of the sky rather than out of a box
            layer.enabled: moving
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: fade
                maskSpreadAtMin: 1
                maskThresholdMin: 0
            }

            Row {
                id: strip

                spacing: 48

                Text {
                    id: title

                    width: view.moving ? implicitWidth : Math.min(implicitWidth, root.limit)
                    elide: Text.ElideRight
                    text: {
                        if (!root.player)
                            return "";
                        const artist = root.player.trackArtist ?? "";
                        return root.player.trackTitle + (artist && Config.mediaTitle === "scroll" ? " · " + artist : "");
                    }
                    color: Theme.textSoft
                    font.family: Theme.font
                    font.pixelSize: Theme.textSize
                }

                Text {
                    visible: view.moving
                    text: title.text
                    color: title.color
                    font: title.font
                }

                NumberAnimation on x {
                    running: view.moving && !pointer.containsMouse
                    loops: Animation.Infinite
                    from: 0
                    to: -(title.implicitWidth + strip.spacing)
                    duration: (title.implicitWidth + strip.spacing) * 30
                }
            }
        }

    }

    Item {
        id: fade

        visible: false
        width: view.width
        height: view.height
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.07; color: "black" }
                GradientStop { position: 0.93; color: "black" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    Hover {
        id: pointer

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: mouse => {
            if (mouse.button === Qt.RightButton)
                root.player?.togglePlaying();
            else
                Menus.toggle("media", root.mapToItem(null, root.width / 2, 0).x);
        }
    }
}
