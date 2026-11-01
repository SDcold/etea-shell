import QtQuick
import qs.config

// A picture seen through a star. Grow the star and the picture opens up.
ShaderEffect {
    id: root

    required property var source
    property real reach: 0
    property real shine: 0
    property real flipped: 0
    property point center: Qt.point(width / 2, height / 2)

    // How big the star must get before it has swallowed the farthest corner too
    readonly property real fullReach: {
        const curve = 0.62;
        const across = Math.max(center.x, width - center.x), down = Math.max(center.y, height - center.y);
        return Math.pow(Math.pow(across, curve) + Math.pow(down, curve), 1 / curve) + 6;
    }

    readonly property color tint: Theme.windowLit
    readonly property vector2d resolution: Qt.vector2d(width, height)

    fragmentShader: Qt.resolvedUrl("../../shaders/starmask.frag.qsb")
}
