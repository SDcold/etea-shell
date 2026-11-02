import QtQuick
import qs.config

// One line being sung: the words fill with light from left to right as the song goes.
// Too long for the width, it shrinks a little rather than wrap.
Item {
    id: root

    property string text: ""
    property real progress: 0
    property color ink: Theme.text
    property real size: 30
    property real dim: 0.32 // how much of the ink the words still to sing keep

    implicitHeight: base.implicitHeight

    Text {
        id: base

        width: root.width
        horizontalAlignment: Text.AlignHCenter
        text: root.text
        color: Qt.alpha(root.ink, root.dim)
        font.family: Theme.font
        font.pixelSize: root.size
        font.weight: Font.Medium
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.size * 0.6
    }

    // The sung part: the same words in full ink, uncovered as far as the song has come
    Item {
        x: (root.width - base.contentWidth) / 2
        width: base.contentWidth * root.progress
        height: base.height
        clip: true

        Text {
            x: -parent.x
            width: base.width
            horizontalAlignment: Text.AlignHCenter
            text: base.text
            color: root.ink
            font: base.font
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: base.minimumPixelSize
        }
    }
}
