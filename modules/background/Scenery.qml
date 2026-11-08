import QtQuick
import qs.config
import qs.modules.background.scenery
import qs.services

// What stands in a world's sky and on its ground. The shapes come from
// scripts/world-scenery.py, each world's scene places them and sets them moving. Twice per
// world: once behind the hills for the sky, once in front of them for anything closer.
Loader {
    id: root

    required property var planet
    property bool front: false
    property real angle: 0 // the planet's turn, which carries what stands on its ground
    property real horizon: 0.9

    readonly property string scene: Planets.sceneOf(planet)
    readonly property real unit: width / 1600 // the hills' own unit
    readonly property real skyUnit: Math.min(width / 1600, height / 900) // so a wide screen doesn't blow the sky up
    readonly property real horizonY: height * horizon

    // Things on the ground ride the planet round as a page turns. One stands on every page,
    // so whichever way it turns, the next one comes into view.
    function groundTurn(copy) {
        const step = Planet.step, turned = (angle % step + step) % step;
        return (copy * step - turned) * 180 / Math.PI;
    }

    readonly property real groundPivot: horizonY + Theme.terrainCurve * unit

    active: scene !== "" && visible
    sourceComponent: ({ Aster: aster })[scene] ?? null

    Component {
        id: aster

        AsterScene {}
    }
}
