import QtQuick

// Aster, after Saturn: from one of its moons, the ringed giant sits low and never sets.
// Three small moons drift across over a quarter of an hour.
Item {
    id: root

    readonly property Item host: parent
    readonly property real u: host.skyUnit
    property real clock: 0 // seconds, in quarter steps: nothing here needs more

    AsterArt {
        id: art
    }

    Timer {
        running: !root.host.front
        repeat: true
        interval: 250
        onTriggered: root.clock += 0.25
    }

    Repeater {
        model: root.host.front ? [] : [{ part: art.moonA, period: 1100, from: 0.15, rise: 300 }, { part: art.moonB, period: 700, from: 0.62, rise: 200 }, { part: art.moonC, period: 1500, from: 0.4, rise: 380 }]

        ArtPart {
            required property var modelData
            readonly property real along: (root.clock / modelData.period + modelData.from) % 1

            part: modelData.part
            planet: root.host.planet
            unit: root.u
            x: along * (root.width + 40 * root.u) - 20 * root.u
            y: root.host.horizonY - (60 + modelData.rise * Math.sin(Math.PI * along)) * root.u
        }
    }

    Repeater {
        model: root.host.front ? [] : [art.ringBack, art.giant, art.ringFront]

        ArtPart {
            required property var modelData

            part: modelData
            planet: root.host.planet
            unit: root.u
            x: root.width * 0.74 - width / 2
            y: root.host.horizonY - 170 * root.u - height / 2
        }
    }
}
