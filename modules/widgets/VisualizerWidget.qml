import QtQuick
import Quickshell.Services.Mpris
import qs.config
import qs.modules.bar
import qs.services

// The music, rising behind the hills as an aurora in the colours of the cover.
// It only listens while there's a page empty enough to see it.
Item {
    id: root

    property real span: 1920

    readonly property var player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }
    readonly property bool listening: Planet.pageEmpty && (player?.isPlaying ?? false)

    implicitWidth: span
    implicitHeight: 620

    function row(first) {
        const levels = Beat.levels;
        return Qt.vector4d(levels[first] ?? 0, levels[first + 1] ?? 0, levels[first + 2] ?? 0, levels[first + 3] ?? 0);
    }

    onListeningChanged: listening ? Beat.join() : Beat.leave()
    Component.onCompleted: {
        if (listening)
            Beat.join();
    }
    Component.onDestruction: {
        if (listening)
            Beat.leave();
    }

    ContentTint {
        id: colour

        image: root.player?.trackArtUrl ?? ""
        name: root.player?.trackTitle ?? "etea"
    }

    ShaderEffect {
        id: aurora

        property vector4d l0: root.row(0)
        property vector4d l1: root.row(4)
        property vector4d l2: root.row(8)
        property vector4d l3: root.row(12)
        property vector4d l4: root.row(16)
        property vector4d l5: root.row(20)
        property vector4d l6: root.row(24)
        property color tint: colour.color
        property color base: Theme.auroraBase
        property vector2d resolution: Qt.vector2d(width, height)
        property real time: 0
        property real presence: root.listening && Beat.levels.length ? 1 : 0

        anchors.fill: parent
        visible: presence > 0.01
        fragmentShader: Qt.resolvedUrl("../../shaders/aurora.frag.qsb")

        Behavior on presence {
            NumberAnimation { duration: 900; easing.type: Easing.InOutSine }
        }
        Behavior on tint {
            ColorAnimation { duration: 800 }
        }

        FrameAnimation {
            running: aurora.visible
            onTriggered: aurora.time += frameTime
        }
    }
}
