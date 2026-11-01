import QtQuick
import Quickshell
import qs.config

// Stack the sky, then the decorations, then the terrain so it sits in front.
Item {
    id: root

    property real angle: 0 // how far the planet has turned

    ShaderEffect {
        anchors.fill: parent

        property color colorTop: Theme.skyTop
        property color colorMid: Theme.skyMid
        property color colorLow: Theme.skyLow
        property vector2d resolution: Qt.vector2d(width, height)
        property real grain: Theme.grain

        fragmentShader: Qt.resolvedUrl("../../shaders/sky.frag.qsb")
    }

    // Everyone's own images, placed by proportion so they fit on any screen
    Repeater {
        model: Config.decorations

        Image {
            required property var modelData

            source: "file://" + Quickshell.shellPath("decorations/" + modelData.file)
            x: modelData.x * root.width - width / 2
            y: modelData.y * root.height - height / 2
            width: modelData.width * root.width
            height: width * (implicitHeight / Math.max(1, implicitWidth))
            sourceSize.width: width
            fillMode: Image.PreserveAspectFit
            opacity: modelData.opacity ?? 1
            rotation: modelData.rotation ?? 0
            smooth: true
        }
    }

    ShaderEffect {
        anchors.fill: parent

        // planetAngle is what will spin the planet between pages
        property color layer0: Theme.terrainLayers[0]
        property color layer1: Theme.terrainLayers[1]
        property color layer2: Theme.terrainLayers[2]
        property color layer3: Theme.terrainLayers[3]
        property vector2d resolution: Qt.vector2d(width, height)
        property real horizon: 1 - Theme.terrainHeight
        property real relief: Theme.terrainRelief
        property real curve: Theme.terrainCurve
        property real planetAngle: root.angle
        property real grain: Theme.grain

        fragmentShader: Qt.resolvedUrl("../../shaders/terrain.frag.qsb")
    }
}
