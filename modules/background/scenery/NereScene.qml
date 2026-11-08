import QtQuick

// Néré, after Neptune: its three ring arcs, Liberté, Égalité and Fraternité, Triton pale
// and pink, mist rolling over the swell, and now and then a fast white cloud racing across.
Item {
    id: root

    readonly property Item host: parent
    readonly property real u: host.skyUnit
    property real clock: 0

    NereArt {
        id: art
    }

    Timer {
        running: root.host.front
        repeat: true
        interval: 250
        onTriggered: root.clock += 0.25
    }

    ArtPart {
        visible: !root.host.front
        part: art.arcs
        planet: root.host.planet
        unit: root.host.unit
        y: root.height * 0.04
    }

    ArtPart {
        visible: !root.host.front
        part: art.triton
        planet: root.host.planet
        unit: root.u
        x: root.width * 0.17
        y: root.height * 0.2
    }

    // The scooter: every few minutes, across in under a minute
    ArtPart {
        id: scooter

        visible: !root.host.front && racing.running
        part: art.scooter
        planet: root.host.planet
        unit: root.u
        y: root.height * 0.32

        NumberAnimation on x {
            id: racing

            running: false
            from: -scooter.width
            to: root.width
            duration: 48000
        }
    }

    Timer {
        running: !root.host.front
        repeat: true
        interval: 150000 + Math.random() * 180000
        onTriggered: {
            interval = 150000 + Math.random() * 180000;
            racing.restart();
        }
    }

    // Two lengths of mist end to end, sliding slowly to the left forever
    Repeater {
        model: root.host.front ? [0, 1] : []

        ArtPart {
            required property int modelData
            readonly property real slid: root.clock * 5 * root.host.unit % width

            part: art.mist
            planet: root.host.planet
            unit: root.host.unit
            x: modelData * width - slid
            y: root.host.horizonY - 62 * root.host.unit
        }
    }
}
