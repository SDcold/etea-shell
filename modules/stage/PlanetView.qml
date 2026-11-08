import QtQuick
import qs.config

// A planet floating in space, drawn by the same shader as the ground under your feet.
ShaderEffect {
    id: root

    required property var planet
    property bool spinning: true
    property real startAngle: 0 // where its turn starts, to pick up from another view of it

    property color layer0: planet.terrain[0]
    property color layer1: planet.terrain[1]
    property color layer2: planet.terrain[2]
    property color layer3: planet.terrain[3]
    property vector2d resolution: Qt.vector2d(width, height)
    property real horizon: 0.1125 // with this curve, the planet sits dead centre
    property real relief: 1
    property real curve: 620
    property real planetAngle: 0
    property real grain: Theme.grain
    property real orbit: 1
    property color rimColor: planet.skyLow

    // The music and its bars only exist on the ground, but the shader asks for them
    property vector4d l0: Qt.vector4d(0, 0, 0, 0)
    property vector4d l1: l0
    property vector4d l2: l0
    property vector4d l3: l0
    property vector4d l4: l0
    property vector4d l5: l0
    property vector4d l6: l0
    property real music: 0
    property real lift: 0
    property real bars: 0
    property real arrival: 0
    property color arrivalLight: "transparent"
    property real rough: planet.rough ?? 1
    property real flatRim: 0

    fragmentShader: Qt.resolvedUrl("../../shaders/terrain.frag.qsb")

    NumberAnimation on planetAngle {
        from: root.startAngle
        to: root.startAngle + Math.PI * 2
        duration: 90000
        loops: Animation.Infinite
        running: root.spinning && root.visible && (root.Window.window?.visible ?? false) // not in a closed window
    }
}
