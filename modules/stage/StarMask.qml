import QtQuick
import qs.config

// A picture seen through a star. Grow the star and the picture opens up.
ShaderEffect {
    id: root

    required property var source
    property real reach: 0
    property real shine: 0

    // How big the star must get before it has swallowed the corners too
    readonly property real fullReach: {
        const curve = 0.62;
        return Math.pow(Math.pow(width / 2, curve) + Math.pow(height / 2, curve), 1 / curve) + 6;
    }

    readonly property color tint: Theme.windowLit
    readonly property vector2d resolution: Qt.vector2d(width, height)

    fragmentShader: Qt.resolvedUrl("../../shaders/starmask.frag.qsb")
}
