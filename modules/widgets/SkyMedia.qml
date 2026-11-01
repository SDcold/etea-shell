import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.modules.bar
import qs.modules.bar.menus
import qs.services

// What's playing, written on the sky with everything you need to steer it. The cover
// and the title melt away a little, the controls stay crisp so they're easy to hit.
RowLayout {
    id: root

    property real sky: 1080
    readonly property var player: Music.player

    spacing: sky * 0.02
    width: sky * 0.45

    ClippingRectangle {
        visible: root.player !== null && cover.status === Image.Ready
        Layout.preferredWidth: root.sky * 0.15
        Layout.preferredHeight: root.sky * 0.15
        Layout.alignment: Qt.AlignTop
        radius: 18
        color: "transparent"

        layer.enabled: true
        layer.effect: Dissolve {
            from: 0.45
            to: 1.05
        }

        Image {
            id: cover

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.sky * 0.3, root.sky * 0.3)
            source: root.player?.trackArtUrl ?? ""
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: root.sky * 0.006

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: root.player ? root.player.trackArtist || "En écoute" : "En attente"
            elide: Text.ElideRight
            color: Theme.skyInk
            font.family: Theme.font
            font.pixelSize: root.sky * 0.016
            font.weight: Font.Medium
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: root.player?.trackTitle ?? "Silence radio."
            elide: Text.ElideRight
            color: Theme.skyInk
            font.family: Theme.font
            font.pixelSize: root.sky * 0.044
            font.weight: Font.Medium
            renderType: Text.CurveRendering

            layer.enabled: true
            layer.smooth: true
            layer.textureSize: Qt.size(width * 2, height * 2) // drawn at double size so the curves come out smooth
            layer.effect: Dissolve {
                from: 0.4
                to: 1.3
            }
        }

        MediaProgress {
            visible: known
            Layout.fillWidth: true
            tint: Theme.skyInk
        }

        MediaControls {
            visible: root.player !== null
            Layout.alignment: Qt.AlignRight
            tint: Theme.skyInk
        }
    }
}
