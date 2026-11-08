import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.modules.background
import qs.services

// The stage sits above the windows and below the bar. It stays empty until a
// page change, then shows a copy of the world for a third of a second.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: stage

        required property var modelData

        readonly property bool focused: Hyprland.focusedMonitor?.name === modelData.name
        readonly property bool showing: focused && Planet.phase >= Planet.Phase.Spinning
        // The planet's centre is way below the screen, so everything swings around it
        readonly property real pivotY: height * (1 - Theme.terrainHeight) + Theme.terrainCurve * width / 1600

        // The camera. All of this hangs off Planet.altitude, 0 on the ground and 1 in orbit.
        readonly property real unit: width / 1600
        readonly property real screenHeight: height / unit
        // How far the pages have climbed onto the planet: all the way once the camera is as
        // high as this trip goes, so a page sits on the dome in the skies as it does in orbit
        readonly property real climbed: Math.min(1, Planet.altitude / Planet.ceiling)
        // Going on up to the planets, the camera keeps rising: the planet shrinks a little
        // and drifts to where the row of worlds will hold it, its pages fall in towards it
        readonly property real beyond: Planet.systemLevel
        readonly property real planetRadius: Math.exp(Math.log(Theme.terrainCurve) + (Math.log(Theme.orbitRadius) - Math.log(Theme.terrainCurve)) * Planet.altitude) * (1 - 0.22 * beyond)
        readonly property real planetTop: {
            const ground = screenHeight * (1 - Theme.terrainHeight);
            const t = Math.max(0, Math.min(1, (Planet.altitude - 0.3) / 0.7));
            const orbit = ground + (screenHeight / 2 - Theme.orbitRadius - ground) * t * t * (3 - 2 * t);
            return orbit + (screenHeight * 0.44 - planetRadius - (screenHeight / 2 - Theme.orbitRadius)) * beyond;
        }

        // Choosing a sky, your own sky folds from the whole screen into ETEA's star, then
        // rounds into a porthole at the zenith, where the belt holds it. All of it hangs off
        // the altitude, so leaving plays it backwards from wherever it is.
        // The planet's centre on screen, and how big the moons of the belt are drawn: they
        // grow and shrink with the planet, and are their true size at the edge
        readonly property point planetCenter: Qt.point(width / 2, (planetTop + planetRadius) * unit)
        readonly property real moonScale: planetRadius / Math.exp(Math.log(Theme.terrainCurve) + (Math.log(Theme.orbitRadius) - Math.log(Theme.terrainCurve)) * Theme.skyEdge)
        // At rest up there, your sky is its moon; on the way up or down, it's this lens
        readonly property bool lensHanded: Planet.inSkies && !Skies.leaving && Planet.altitude >= Planet.ceiling

        // Choosing a sky, your own sky folds from the whole screen into ETEA's star, then
        // rounds into its moon on the belt, at the zenith. All of it hangs off the altitude,
        // so leaving plays it backwards, from wherever that moon has turned to.
        readonly property var lens: {
            if (Planet.ceiling === 1)
                return null;
            const v = Math.max(0, Math.min(1, Planet.altitude / Planet.ceiling));
            const span = (from, to) => Math.max(0, Math.min(1, (v - from) / (to - from)));
            const inOutCubic = t => t < 0.5 ? 4 * t * t * t : 1 - Math.pow(2 - 2 * t, 3) / 2;
            const inOutSine = t => (1 - Math.cos(Math.PI * t)) / 2;
            // Your sky's moon, or the zenith if it has turned out of sight
            const d = Skies.yours;
            const near = Math.abs(d) < 5;
            const moon = Skies.placeOf(near ? d : 0, planetCenter, Theme.skyBelt * planetRadius * unit, unit, moonScale, width / height);
            const half = near ? moon.halfHeight * moon.aspect : 1;
            // Far enough for the star to cover every corner, as StarMask reaches
            const full = Math.pow(Math.pow(width / 2, 0.62) + Math.pow(height / 2, 0.62), 1 / 0.62) + 6;
            const toMoon = inOutSine(span(0.3, 1)), round = inOutCubic(span(0.55, 0.95));
            return {
                x: width / 2 + (moon.x - width / 2) * toMoon,
                y: height / 2 + (moon.y - height / 2) * toMoon,
                reach: full * Math.pow(half / full, inOutCubic(span(0.05, 0.85))),
                exponent: 0.62 + (moon.exponent - 0.62) * round,
                aspect: 1 + ((near ? moon.aspect : 1) - 1) * round,
                hills: Skies.leaving && near ? Skies.formed * span(0.75, 1) : 0,
                // Its ring and star go with it as it leaves, and come with the moon as it lands
                ring: Skies.leaving && near ? Skies.formed * span(0.85, 1) : 0,
                light: Skies.planet.light,
                starSize: (4.5 + 3 * moon.z) * unit,
                gap: (4.5 + 3 * moon.z) * unit + 4 * unit,
                seed: Skies.seedOf(Skies.items[Skies.wearing]),
                wobbly: 1 - moon.z,
                starLit: moon.z > 0.5 ? 1 : 0,
                hidden: lensHanded
            };
        }

        // At the edge: arrows a moon at a time, Page Up and Down a screenful, Home back to
        // your own sky, and typing goes to the picture whose name starts that way
        function skyKey(event) {
            if (!lensHanded)
                return;
            if (event.key === Qt.Key_Left)
                Skies.step(-1);
            else if (event.key === Qt.Key_Right)
                Skies.step(1);
            else if (event.key === Qt.Key_PageUp)
                Skies.flyTo(Skies.zenith - 9);
            else if (event.key === Qt.Key_PageDown)
                Skies.flyTo(Skies.zenith + 9);
            else if (event.key === Qt.Key_Home)
                Skies.flyTo(Skies.wearing);
            else if (event.text.length === 1 && event.text.trim() !== "" && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
                Skies.type(event.text);
        }

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "etea:stage"
        WlrLayershell.keyboardFocus: Planet.aloft ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Empty region: clicks and keys go straight through, even mid-spin.
        // Up in orbit or in the skies it's the other way round, the whole screen listens.
        property Region passThrough: Region {}
        property Region everything: Region {
            width: stage.width
            height: stage.height
        }

        mask: Planet.aloft ? everything : passThrough

        // One photo per page, kept around for when we come back
        Item {
            anchors.fill: parent
            opacity: 0

            Repeater {
                id: photos

                model: Config.pages

                PageSnapshot {
                    required property int index

                    anchors.fill: parent
                    output: stage.modelData
                }
            }
        }

        Item {
            id: scene

            anchors.fill: parent
            opacity: stage.showing ? Planet.sceneOpacity : 0
            // Fade as one flat picture, or the sky would shine through the windows
            layer.enabled: stage.showing

            // Built while the photos are taken, gone at rest: even unseen, every clock tick and
            // gauge in it would redraw this whole window, on top of every app
            Loader {
                id: world

                anchors.fill: parent
                // Only the focused screen ever shows its stage
                active: stage.focused && Planet.phase !== Planet.Phase.Idle

                sourceComponent: World {
                    angle: Planet.resting + Planet.travel - Planet.handTurn
                    radius: stage.planetRadius
                    horizon: stage.planetTop / stage.screenHeight
                    space: Math.min(1, Planet.altitude * 1.6)
                    groundOpacity: 1 - Planet.systemLevel
                    lens: stage.lens
                    cached: false
                    listening: Planet.ceiling === 1 // choosing a sky, the ground doesn't dance

                    belt: Component {
                        SkyBelt {
                            center: stage.planetCenter
                            planetRadius: stage.planetRadius * stage.unit
                            unit: stage.unit
                            grow: stage.moonScale
                            showYours: stage.lensHanded
                        }
                    }
                }
            }

            // Your pages, standing around the planet
            Repeater {
                model: Planet.orbitPages

                StagePage {
                    opacity: 1 - Planet.systemLevel
                    // Choosing a sky, only the page you're on comes along
                    visible: Planet.ceiling === 1 || page === Planet.origin
                    required property var modelData
                    required property int index

                    anchors.fill: parent
                    windows: stage.focused ? modelData : []
                    readonly property int page: Planet.orbitStart + index

                    photo: Planet.layouts[page] === Planet.layoutOf(modelData) && Planet.hasPhoto(page) ? photos.itemAt(index)?.frame ?? null : null
                    pivotY: (stage.planetTop + stage.planetRadius) * stage.unit
                    screenX: stage.modelData.x
                    screenY: stage.modelData.y
                    angle: Planet.shortestSteps(Planet.origin, page) * Planet.step - Planet.travel + Planet.handTurn
                    zoom: Math.exp(Math.log(Theme.orbitCard) * Planet.altitude) * (1 - 0.55 * stage.beyond)
                    lift: (stage.planetTop * stage.unit - stage.height) * stage.climbed
                    orbitCard: true
                    pointedAt: Planet.hoveredPage === index
                }
            }

            StagePage {
                anchors.fill: parent
                windows: stage.focused ? Planet.leaving : []
                backdrop: world.item
                photo: photos.itemAt(Planet.slotOf(Planet.origin))?.frame ?? null
                pivotY: stage.pivotY
                screenX: stage.modelData.x
                screenY: stage.modelData.y
                angle: -Planet.travel
            }

            StagePage {
                anchors.fill: parent
                windows: stage.focused ? Planet.arriving : []
                backdrop: world.item
                photo: Planet.arrivalKnown ? photos.itemAt(Planet.slotOf(Planet.target))?.frame ?? null : null
                pivotY: stage.pivotY
                screenX: stage.modelData.x
                screenY: stage.modelData.y
                angle: Planet.remaining
            }
        }

        WindowFrames {
            anchors.fill: parent
            screenX: stage.modelData.x
            screenY: stage.modelData.y
            active: stage.focused && Planet.phase !== Planet.Phase.Spinning && Planet.altitude === 0
        }

        WindowBirth {
            anchors.fill: parent
            output: stage.modelData
            active: stage.focused
        }

        WindowExit {
            anchors.fill: parent
            output: stage.modelData
            screenX: stage.modelData.x
            screenY: stage.modelData.y
        }

        OrbitHands {
            anchors.fill: parent
            pivotY: (stage.planetTop + stage.planetRadius) * stage.unit
            zoom: Math.exp(Math.log(Theme.orbitCard) * Planet.altitude)
            lift: (stage.planetTop * stage.unit - stage.height) * stage.climbed
            screenX: stage.modelData.x
            screenY: stage.modelData.y
        }

        ThemeSystem {
            anchors.fill: parent
        }

        SkyHands {
            anchors.fill: parent
            enabled: stage.lensHanded
            center: stage.planetCenter
            planetRadius: stage.planetRadius * stage.unit
            unit: stage.unit
            grow: stage.moonScale
            card: {
                const zoom = Math.exp(Math.log(Theme.orbitCard) * Planet.altitude);
                const bottom = stage.planetTop * stage.unit;
                return Qt.rect(stage.width * (1 - zoom) / 2, bottom - stage.height * zoom, stage.width * zoom, stage.height * zoom);
            }
        }

        // In orbit: Escape goes down a level, 1 to 6 land on a page.
        // Up in the system: left and right pick a planet, Enter lands on it.
        Item {
            focus: Planet.aloft
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    Planet.inSkies ? Skies.leave() : Planet.goDown();
                else if (Planet.inSkies)
                    stage.skyKey(event);
                else if (Planet.inSystem && event.key === Qt.Key_Left)
                    Planet.chooseStep(-1);
                else if (Planet.inSystem && event.key === Qt.Key_Right)
                    Planet.chooseStep(1);
                else if (Planet.inSystem && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter))
                    Planet.land(Planets.all[Planet.systemChoice].id);
                else if (!Planet.inSystem && event.key === Qt.Key_Left)
                    Planet.nudge(1);
                else if (!Planet.inSystem && event.key === Qt.Key_Right)
                    Planet.nudge(-1);
                else if (!Planet.inSystem && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter))
                    Planet.leaveOrbit(Planet.topPage);
                else if (!Planet.inSystem && event.key >= Qt.Key_1 && event.key < Qt.Key_1 + Math.min(9, Config.pages))
                    Planet.leaveOrbit(Planet.orbitStart + event.key - Qt.Key_1);
                else if (!Planet.inSystem && event.key === Qt.Key_0 && Config.pages === 10)
                    Planet.leaveOrbit(Planet.orbitStart + 9);
            }
        }

        // Every move is measured, so we know if it's really smooth
        FrameMeter {
            name: "spin"
            running: stage.focused && Planet.phase === Planet.Phase.Spinning
        }

        FrameMeter {
            name: "turn"
            running: stage.focused && Skies.turning
        }

        FrameMeter {
            name: "climb"
            running: stage.focused && ((Planet.altitude > 0 && Planet.altitude < Planet.ceiling) || (Planet.systemLevel > 0 && Planet.systemLevel < 1))
        }

        Connections {
            target: Skies

            function onGrabWanted(path) {
                if (stage.focused)
                    scene.grabToImage(result => console.info(`ETEA grab: ${result.saveToFile(path) ? path : "failed"}`));
            }
        }

        Connections {
            target: Planet

            function onPhotoNeeded(page, slot) {
                if (stage.focused)
                    photos.itemAt(slot)?.capture();
            }

            function onFinished(prepareMs) {
                if (stage.focused)
                    console.info(`ETEA ready: ${prepareMs} ms after the key press, ${Planet.captured}/${Planet.expected} captures`);
            }
        }
    }
}
