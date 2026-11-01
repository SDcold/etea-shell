import QtQuick
import qs.config
import qs.services

// The moment you land on a new world, the air burns around you.
ShaderEffect {
    id: root

    property color fire: Theme.skyLow
    property real time: 0
    property real heat: Planet.landing ? Math.pow(Math.sin(Math.min(1, Planet.altitude) * Math.PI), 1.5) : 0
    property real ratio: width / Math.max(1, height)

    visible: heat > 0.01
    fragmentShader: Qt.resolvedUrl("../../shaders/atmosphere.frag.qsb")

    FrameAnimation {
        running: root.visible
        onTriggered: root.time += frameTime
    }
}
