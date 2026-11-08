import QtQuick
import Quickshell.Widgets
import qs.config
import qs.modules.bar
import qs.modules.settings
import qs.services

// The pictures themselves, on their card. Only the thumbnails on screen are made, each one
// loaded off the main thread at its own small size, then kept so the next time is instant.
Item {
    id: card

    function begin() {
        wall.currentIndex = 0;
        wall.positionViewAtBeginning();
        wall.forceActiveFocus();
    }

    HandCard {
        anchors.fill: parent
        seed: "pictures"
        tint: Theme.windowLit
        rise: 0.05
        alive: Pictures.open
    }

    // Clicks on the card stay on the card
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: heading

        x: 32
        y: 26
        spacing: 2

        Text {
            text: Pictures.title
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 22
            font.weight: Font.Light
        }

        Text {
            text: Pictures.listing ? "…" : Lang.t("{0} images dans {1}", Pictures.pictures.length, Pictures.folder.replace(Pictures.home, "~"))
            color: Qt.alpha(Theme.text, 0.6)
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    SettingButton {
        anchors.right: parent.right
        anchors.rightMargin: 32
        anchors.verticalCenter: heading.verticalCenter
        label: Lang.t("Autre dossier…")
        quiet: true
        onPicked: Pictures.browse()
    }

    Text {
        anchors.centerIn: parent
        visible: !Pictures.listing && Pictures.pictures.length === 0
        width: parent.width * 0.6
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: Lang.t("Aucune image ici pour l'instant. Pose tes fonds d'écran dans {0}, ou va les chercher ailleurs.", Pictures.folder.replace(Pictures.home, "~"))
        color: Qt.alpha(Theme.text, 0.7)
        font.family: Theme.font
        font.pixelSize: 14
    }

    GridView {
        id: wall

        readonly property int columns: Math.max(2, Math.floor(width / 250))

        x: 24
        y: heading.y + heading.height + 18
        width: parent.width - 48
        height: parent.height - y - 24
        clip: true
        model: Pictures.pictures
        cellWidth: width / columns
        cellHeight: cellWidth * 0.66
        cacheBuffer: cellHeight * 2 // one row ready on each side, no more
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: true
        focus: Pictures.open

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                Pictures.close();
            else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && currentIndex >= 0)
                Pictures.choose(Pictures.pictures[currentIndex].path);
        }

        delegate: Item {
            id: tile

            required property var modelData
            required property int index

            readonly property bool lit: pointer.containsMouse || (GridView.isCurrentItem && wall.activeFocus && !wall.moving)

            width: wall.cellWidth
            height: wall.cellHeight

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 8
                radius: 14
                color: Qt.lighter(Theme.cardDeep, 1.5)
                border.width: tile.lit ? 2 : 0
                border.color: Theme.windowLit
                scale: tile.lit ? 1.03 : 1

                Behavior on scale {
                    NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                }

                Image {
                    id: thumb

                    // 0: the system's thumbnail, 1: ours, 2: the picture itself
                    property int stage: Pictures.firstStage(tile.modelData)
                    property bool kept: false

                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(Math.ceil(width * 1.5), Math.ceil(height * 1.5))
                    source: [Pictures.url(Pictures.systemThumb(tile.modelData.path)), Pictures.url(Pictures.ownThumb(tile.modelData)), Pictures.url(tile.modelData.path)][stage]
                    opacity: status === Image.Ready ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.fast }
                    }

                    onStatusChanged: {
                        if (status === Image.Error && stage < 2)
                            stage += 1;
                    }

                    // Made from the picture itself: once it's fully in, keep it small for next time
                    onOpacityChanged: {
                        if (opacity === 1 && stage === 2 && !kept) {
                            kept = true;
                            const file = Pictures.ownThumb(tile.modelData);
                            grabToImage(result => result.saveToFile(file), sourceSize);
                        }
                    }
                }

                // The name, on a flat band, while you hover
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 26
                    color: Qt.alpha(Theme.cardDeep, 0.8)
                    visible: tile.lit

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        text: tile.modelData.path.split("/").pop()
                        elide: Text.ElideMiddle
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 11
                    }
                }
            }

            // A recycled tile starts over from the quickest source for its new picture
            GridView.onReused: {
                thumb.stage = Pictures.firstStage(tile.modelData);
                thumb.kept = false;
            }

            MouseArea {
                id: pointer

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: Pictures.choose(tile.modelData.path)
            }
        }
    }
}
