import QtQuick
import qs.services

// Aster, after Saturn: from one of its moons, the ringed giant sits low and never sets.
// Three small moons drift across over a quarter of an hour.
Item {
    id: root

    readonly property Item host: parent
    readonly property real u: host.skyUnit
    // Only while someone can see it: the page empty, and this copy's window shown
    readonly property bool moving: Orrery.running && visible && (Window.window?.visible ?? false)

    AsterArt {
        id: art
    }

    // Each moon rides an arc through both edges of the screen: an arm turning about a pivot
    // far below the horizon, the moon held upright at its end. The turning happens on the
    // render thread, so it glides at the screen's own rate and costs no script at all.
    Repeater {
        model: root.host.front ? [] : [{ part: art.moonA, period: 1100, from: 0.15, rise: 300 }, { part: art.moonB, period: 700, from: 0.62, rise: 200 }, { part: art.moonC, period: 1500, from: 0.4, rise: 380 }]

        Item {
            id: orbit

            required property var modelData
            // The circle through both ends, just past the screen's edges, and the top of the arc
            readonly property real half: root.width / 2 + 40 * root.u
            readonly property real sag: modelData.rise * root.u
            readonly property real radius: (half * half + sag * sag) / (2 * sag)
            readonly property real sweep: Math.asin(Math.min(1, half / radius)) * 180 / Math.PI

            // Where the arm points at a given second of sky time
            function angleAt(seconds) {
                const along = (seconds / modelData.period + modelData.from) % 1;
                return -sweep + 2 * sweep * along;
            }

            function settle() {
                travel.stop();
                arm.rotation = angleAt(Orrery.now());
                moon.rotation = -arm.rotation;
                if (!root.moving)
                    return;
                // First the rest of this crossing, then every crossing after it
                const left = (sweep - arm.rotation) / (2 * sweep);
                armRest.from = arm.rotation;
                moonRest.from = -arm.rotation;
                armRest.duration = moonRest.duration = Math.max(1, left * modelData.period * 1000);
                travel.start();
            }

            x: root.width / 2
            y: root.host.horizonY - 60 * root.u - sag + radius

            Component.onCompleted: settle()
            onSweepChanged: settle()

            Connections {
                target: root

                function onMovingChanged() {
                    orbit.settle();
                }
            }

            Item {
                id: arm

                ArtPart {
                    id: moon

                    part: orbit.modelData.part
                    planet: root.host.planet
                    unit: root.u
                    x: -width / 2
                    y: -orbit.radius - height / 2
                }
            }

            SequentialAnimation {
                id: travel

                ParallelAnimation {
                    RotationAnimator {
                        id: armRest

                        target: arm
                        to: orbit.sweep
                    }

                    RotationAnimator {
                        id: moonRest

                        target: moon
                        to: -orbit.sweep
                    }
                }

                ParallelAnimation {
                    loops: Animation.Infinite

                    RotationAnimator {
                        target: arm
                        from: -orbit.sweep
                        to: orbit.sweep
                        duration: orbit.modelData.period * 1000
                    }

                    RotationAnimator {
                        target: moon
                        from: orbit.sweep
                        to: -orbit.sweep
                        duration: orbit.modelData.period * 1000
                    }
                }
            }
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
