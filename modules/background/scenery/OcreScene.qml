import QtQuick

// Ocre, after Mars: Olympus Mons on the horizon, a sunset gone blue around the sun, Phobos
// rising in the west and racing across, Deimos crawling the other way, dust drifting
// through, and once in a while a dust devil wandering over the dunes.
Item {
    id: root

    readonly property Item host: parent
    readonly property real u: host.skyUnit
    property real clock: 0

    OcreArt {
        id: art
    }

    Timer {
        repeat: true
        running: true
        interval: 250
        onTriggered: root.clock += 0.25
    }

    ArtPart {
        visible: !root.host.front
        part: art.sun
        planet: root.host.planet
        unit: root.u
        x: root.width * 0.84 - width / 2
        y: root.host.horizonY - 34 * root.u - height / 2
    }

    // Deimos takes half an hour to cross, from east to west
    ArtPart {
        readonly property real along: 1 - (root.clock / 1800 + 0.3) % 1

        visible: !root.host.front
        part: art.deimos
        planet: root.host.planet
        unit: root.u
        x: along * root.width
        y: root.host.horizonY - (90 + 330 * Math.sin(Math.PI * along)) * root.u
    }

    // Phobos goes the other way, and fast
    ArtPart {
        id: phobos

        property real along: 0

        visible: !root.host.front && crossing.running
        part: art.phobos
        planet: root.host.planet
        unit: root.u
        x: along * (root.width + width) - width
        y: root.host.horizonY - (80 + 260 * Math.sin(Math.PI * along)) * root.u

        NumberAnimation on along {
            id: crossing

            running: false
            from: 0
            to: 1
            duration: 75000
        }
    }

    Timer {
        running: !root.host.front
        repeat: true
        interval: 240000 + Math.random() * 120000
        onTriggered: {
            interval = 240000 + Math.random() * 120000;
            crossing.restart();
        }
    }

    // Olympus Mons stands on the ground, so it turns with the planet
    Repeater {
        model: root.host.front ? [] : [-1, 0, 1]

        ArtPart {
            required property int modelData

            part: art.olympus
            planet: root.host.planet
            unit: root.host.unit
            x: root.width * 0.36 - width / 2
            y: root.host.horizonY + 6 * root.host.unit - height
            transform: Rotation {
                origin.x: root.width / 2 - x
                origin.y: root.host.groundPivot - y
                angle: root.host.groundTurn(modelData)
            }
        }
    }

    Repeater {
        model: root.host.front ? [0, 1] : []

        ArtPart {
            required property int modelData
            readonly property real slid: root.clock * 9 * root.host.unit % width

            part: art.dust
            planet: root.host.planet
            unit: root.host.unit
            x: modelData * width - width + slid
            y: root.height - height
        }
    }

    // The dust devil: it fades in a step at a time, wanders, sways, and fades out the same way
    ArtPart {
        id: devil

        property real along: 0

        visible: root.host.front && wandering.running
        part: art.devil
        planet: root.host.planet
        unit: root.host.unit
        x: root.width * (0.12 + 0.4 * along)
        y: root.host.horizonY + 28 * root.host.unit - height
        opacity: Math.min(1, Math.floor(Math.min(along, 1 - along) * 4 / 0.25) / 4)
        rotation: 4 * Math.sin(root.clock * 1.3)
        transformOrigin: Item.Bottom

        NumberAnimation on along {
            id: wandering

            running: false
            from: 0
            to: 1
            duration: 42000
        }
    }

    Timer {
        running: root.host.front
        repeat: true
        interval: 200000 + Math.random() * 160000
        onTriggered: {
            interval = 200000 + Math.random() * 160000;
            wandering.restart();
        }
    }
}
