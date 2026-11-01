import QtQuick
import qs.config

// The light around the focused window. The real window and its stand-in share this,
// so nothing changes the moment one takes over from the other.
ShaderEffect {
    id: root

    required property size window

    readonly property color tint: Theme.windowLit
    readonly property vector2d resolution: Qt.vector2d(width, height)
    readonly property vector2d windowSize: Qt.vector2d(window.width, window.height)
    readonly property real radius: Theme.windowRadius
    readonly property real reach: Theme.windowGlowSize
    readonly property real strength: Theme.windowGlow
    readonly property real softness: Theme.windowGlowPower

    fragmentShader: Qt.resolvedUrl("../../shaders/glow.frag.qsb")
}
