import QtQuick
import qs.config

// A planet floating in space, drawn by the same shader as the ground under your feet.
ShaderEffect {
    id: root

    required property var planet
    property bool spinning: true

    property color layer0: planet.terrain[0]
    property color layer1: planet.terrain[1]
    property color layer2: planet.terrain[2]
    property color layer3: planet.terrain[3]
    property vector2d resolution: Qt.vector2d(width, height)
    property real horizon: 0.1125 // with this curve, the planet sits dead centre
    property real relief: 1
    property real curve: 620
    property real planetAngle: 0
    property real grain: 0.34
    property real orbit: 1
    property color rimColor: planet.skyLow

    fragmentShader: Qt.resolvedUrl("../../shaders/terrain.frag.qsb")

    NumberAnimation on planetAngle {
        from: 0
        to: Math.PI * 2
        duration: 90000
        loops: Animation.Infinite
        running: root.spinning && root.visible
    }
}
