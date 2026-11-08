import QtQuick

// Vesper, after Venus: clouds turning faster than the ground beneath them, lightning
// inside them, flat round volcanoes, and far up a tiny blue star with its moon: home.
Item {
    id: root

    readonly property Item host: parent
    readonly property real u: host.skyUnit
    property real clock: 0
    property real boltAt: 0.5
    property bool striking: false

    VesperArt {
        id: art
    }

    Timer {
        running: !root.host.front
        repeat: true
        interval: 250
        onTriggered: root.clock += 0.25
    }

    ArtPart {
        visible: !root.host.front
        part: art.home
        planet: root.host.planet
        unit: root.u
        x: root.width * 0.63
        y: root.height * 0.34
    }

    // The cloud deck runs right to left, end to end, and lights up from inside when it strikes
    Repeater {
        model: root.host.front ? [] : [0, 1]

        Item {
            required property int modelData
            readonly property real slid: root.clock * 7 * root.host.unit % width

            width: clouds.width
            height: clouds.height
            x: modelData * width - slid

            ArtPart {
                id: clouds

                part: art.clouds
                planet: root.host.planet
                unit: root.host.unit
            }

            ArtPart {
                visible: root.striking
                part: art.flash
                planet: root.host.planet
                unit: root.host.unit
            }
        }
    }

    ArtPart {
        visible: !root.host.front && root.striking
        part: art.bolt
        planet: root.host.planet
        unit: root.u
        x: root.width * root.boltAt
        y: root.height * 0.13
    }

    // On, off, on again, then gone: a strike in flat frames
    SequentialAnimation {
        id: strike

        PropertyAction { target: root; property: "striking"; value: true }
        PauseAnimation { duration: 70 }
        PropertyAction { target: root; property: "striking"; value: false }
        PauseAnimation { duration: 90 }
        PropertyAction { target: root; property: "striking"; value: true }
        PauseAnimation { duration: 50 }
        PropertyAction { target: root; property: "striking"; value: false }
    }

    Timer {
        running: !root.host.front
        repeat: true
        interval: 15000 + Math.random() * 35000
        onTriggered: {
            interval = 15000 + Math.random() * 35000;
            root.boltAt = 0.1 + Math.random() * 0.8;
            strike.restart();
        }
    }

    // The volcanoes stand close, in front of the hills, and turn with the planet
    Repeater {
        model: root.host.front ? [-1, 0, 1] : []

        ArtPart {
            required property int modelData

            part: art.domes
            planet: root.host.planet
            unit: root.host.unit
            x: -50 * root.host.unit
            y: root.height - height + 2
            transform: Rotation {
                origin.x: root.width / 2 - x
                origin.y: root.host.groundPivot - y
                angle: root.host.groundTurn(modelData)
            }
        }
    }
}
