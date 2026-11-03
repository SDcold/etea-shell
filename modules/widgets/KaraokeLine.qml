import QtQuick
import QtQuick.Effects
import qs.config
import qs.modules.bar
import qs.services

// One line being sung, in the shell's own ink. The words still to come wait in faint ink,
// the sung ones take your world's light and glow a little, and a fine thread runs under
// them with a star riding it at the point the song has reached. Between two lines, three
// small stars breathe in its place. Too long for the width, it shrinks rather than wrap.
Item {
    id: root

    property string text: ""
    property real progress: 0
    property bool resting: false // between two lines, nothing to sing
    property color ink: Theme.text
    property color light: Theme.windowLit
    property real size: 30
    property real dim: 0.32 // how much of the ink the words still to sing keep

    readonly property color lit: Qt.tint(ink, Qt.alpha(light, 0.6))
    readonly property real inset: (width - base.contentWidth) / 2

    implicitHeight: base.implicitHeight + size * 0.5

    Text {
        id: base

        visible: !root.resting
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

    // The sung part: the same words in your world's light, uncovered as the song goes,
    // with a soft halo like the stars have
    Item {
        visible: !root.resting
        x: root.inset
        width: base.contentWidth * root.progress
        height: base.height
        clip: true

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.light
            shadowBlur: 0.7
            shadowOpacity: 0.55
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            autoPaddingEnabled: true
        }

        Text {
            x: -parent.x
            width: base.width
            horizontalAlignment: Text.AlignHCenter
            text: base.text
            color: root.lit
            font: base.font
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: base.minimumPixelSize
        }
    }

    // The thread under the words, lit as far as the song has come, a star riding its tip
    Item {
        id: thread

        visible: !root.resting && base.contentWidth > 0
        x: root.inset
        y: base.height + root.size * 0.12
        width: base.contentWidth
        height: 1

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(root.light, 0.22)
        }

        Rectangle {
            width: parent.width * root.progress
            height: 1
            color: Qt.alpha(root.light, 0.85)
        }

        Star {
            x: parent.width * root.progress - size
            y: -size
            size: Math.max(4, root.size * 0.16)
            lit: true
            animated: false
        }
    }

    // A pause in the song: three stars breathing, one after the other
    Row {
        visible: root.resting
        anchors.horizontalCenter: parent.horizontalCenter
        y: (base.height - height) / 2
        spacing: root.size * 0.5

        Repeater {
            model: 3

            Star {
                required property int index

                size: Math.max(4, root.size * 0.18)
                lit: true
                animated: false
                opacity: 0.35 + 0.65 * Math.max(0, Math.sin(Drift.time * 2.4 - index * 0.9))
            }
        }
    }

    // The breathing rides the shared sky clock, only while it shows
    property bool ticking: false

    function tick() {
        const wanted = resting && visible;
        if (wanted === ticking)
            return;
        ticking = wanted;
        wanted ? Drift.join() : Drift.leave();
    }

    onRestingChanged: tick()
    onVisibleChanged: tick()
    Component.onCompleted: tick()
    Component.onDestruction: {
        if (ticking)
            Drift.leave();
    }
}
