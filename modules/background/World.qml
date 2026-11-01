import QtQuick
import Quickshell
import qs.config
import qs.modules.widgets
import qs.services

// Stack the sky, the decorations, the widgets, then the terrain so it sits in front.
Item {
    id: root

    property real angle: 0 // how far the planet has turned
    property real radius: Theme.terrainCurve // shrink it and the ground becomes a planet
    property real horizon: 1 - Theme.terrainHeight
    property real space: 0

    // Four sound levels at a time, the way the shader wants them
    function bands(first) {
        const levels = Beat.levels;
        return Qt.vector4d(levels[first] ?? 0, levels[first + 1] ?? 0, levels[first + 2] ?? 0, levels[first + 3] ?? 0);
    }

    ShaderEffect {
        anchors.fill: parent

        property color colorTop: Theme.skyTop
        property color colorMid: Theme.skyMid
        property color colorLow: Theme.skyLow
        property vector2d resolution: Qt.vector2d(width, height)
        property real grain: Theme.grain
        property real space: root.space

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

    Widgets {
        anchors.fill: parent
        opacity: 1 - root.space * 3
        visible: opacity > 0
    }

    ShaderEffect {
        anchors.fill: parent

        // planetAngle is what will spin the planet between pages
        property color layer0: Theme.terrainLayers[0]
        property color layer1: Theme.terrainLayers[1]
        property color layer2: Theme.terrainLayers[2]
        property color layer3: Theme.terrainLayers[3]
        property vector2d resolution: Qt.vector2d(width, height)
        property real horizon: root.horizon
        property real relief: Theme.terrainRelief
        property real curve: root.radius
        property real planetAngle: root.angle
        property real orbit: root.space
        property color rimColor: Theme.skyLow
        property vector4d l0: root.bands(0)
        property vector4d l1: root.bands(4)
        property vector4d l2: root.bands(8)
        property vector4d l3: root.bands(12)
        property vector4d l4: root.bands(16)
        property vector4d l5: root.bands(20)
        property vector4d l6: root.bands(24)
        property real music: Beat.dancing && Beat.levels.length ? 1 : 0

        Behavior on music {
            NumberAnimation { duration: 700; easing.type: Easing.InOutSine }
        }
        property real grain: Theme.grain

        fragmentShader: Qt.resolvedUrl("../../shaders/terrain.frag.qsb")
    }
}
