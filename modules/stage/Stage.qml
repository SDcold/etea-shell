import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.modules.background
import qs.modules.bar
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

        // The planet's centre on screen, and how big the moons of the belt are drawn: they
        // grow and shrink with the planet, and are their true size at the edge
        readonly property point planetCenter: Qt.point(width / 2, (planetTop + planetRadius) * unit)
        readonly property real moonScale: planetRadius / Math.exp(Math.log(Theme.terrainCurve) + (Math.log(Theme.orbitRadius) - Math.log(Theme.terrainCurve)) * Theme.skyEdge)
        // At rest up there, your sky is its moon; on the way up or down, it's this lens
        readonly property bool lensHanded: Planet.inSkies && !Skies.leaving && Planet.altitude >= Planet.ceiling

        // Skies tried on up there sweep out of their moon, which moves with the camera
        readonly property var tryOn: {
            if (Planet.ceiling === 1)
                return null;
            const from = Skies.placeOf(Skies.sweepFrom, planetCenter, Theme.skyBelt * planetRadius * unit, unit, moonScale, width / height);
            const across = Math.max(from.x, width - from.x), down = Math.max(from.y, height - from.y);
            const full = Math.pow(Math.pow(across, 0.62) + Math.pow(down, 0.62), 1 / 0.62) + 6;
            return { shown: Skies.shown, next: Skies.next, x: from.x, y: from.y, reach: full * Skies.sweep };
        }

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
            // Far enough for the star to cover every corner, as StarMask reaches
            const full = Math.pow(Math.pow(width / 2, 0.62) + Math.pow(height / 2, 0.62), 1 / 0.62) + 6;
            const belt = Theme.skyBelt * planetRadius * unit;

            // Looking or landing: the chosen moon grows back into a whole sky, on the way
            // down. It drifts to the middle and rounds into the star, which
            // opens to the corners.
            if (Skies.looking || Skies.landing) {
                const u = 1 - v;
                const along = (from, to) => Math.max(0, Math.min(1, (u - from) / (to - from)));
                const m = Skies.placeOf(Skies.chosenAt, planetCenter, belt, unit, moonScale, width / height);
                const sky = Skies.lensOf(Skies.chosen);
                const half = m.halfHeight * m.aspect, k = along(0, 0.6), shape = inOutCubic(along(0.15, 0.6));
                return {
                    x: m.x + (width / 2 - m.x) * inOutSine(k),
                    y: m.y + (height / 2 - m.y) * k * k * k,
                    reach: half * Math.pow(full / half, inOutCubic(along(0.1, 0.7))),
                    exponent: m.exponent + (0.62 - m.exponent) * shape,
                    aspect: m.aspect + (1 - m.aspect) * shape,
                    ring: 1 - along(0, 0.15),
                    light: sky.palette?.light ?? Skies.planet.light,
                    starSize: (4.5 + 3 * m.z) * unit,
                    gap: (4.5 + 3 * m.z) * unit + 4 * unit,
                    seed: sky.seed,
                    wobbly: 1 - m.z,
                    starLit: 1,
                    hidden: false,
                    path: sky.path,
                    thumb: sky.thumb,
                    palette: sky.palette,
                    painted: sky.painted
                };
            }

            // Your sky's moon, or the zenith if it has turned out of sight
            const d = Skies.yours;
            const near = Math.abs(d) < 5;
            const moon = Skies.placeOf(near ? d : 0, planetCenter, belt, unit, moonScale, width / height);
            const half = near ? moon.halfHeight * moon.aspect : 1;
            const toMoon = inOutSine(span(0.3, 1)), round = inOutCubic(span(0.55, 0.95));
            return {
                x: width / 2 + (moon.x - width / 2) * toMoon,
                y: height / 2 + (moon.y - height / 2) * toMoon,
                reach: full * Math.pow(half / full, inOutCubic(span(0.05, 0.85))),
                exponent: 0.62 + (moon.exponent - 0.62) * round,
                aspect: 1 + ((near ? moon.aspect : 1) - 1) * round,
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
            // Looking at a sky, Enter lands it
            if (Skies.looking && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter))
                Skies.choose();
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
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                Skies.choose();
            else if (event.key === Qt.Key_Space && !event.isAutoRepeat)
                Skies.look(true);
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
                    tryOn: stage.tryOn
                    cached: false
                    listening: Planet.ceiling === 1 // choosing a sky, the ground doesn't dance

                    belt: Component {
                        SkyBelt {
                            center: stage.planetCenter
                            planetRadius: stage.planetRadius * stage.unit
                            unit: stage.unit
                            grow: stage.moonScale
                            showYours: stage.lensHanded || Skies.looking || Skies.landing
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

        // A picture asked for somewhere: its moon folds into a star and flies home to the
        // control that asked, tracked on your page as it comes back down, so the star
        // touches the button just as the page is full size again
        Item {
            id: homing

            readonly property real u: Skies.homing ? 1 - Math.max(0, Math.min(1, Planet.altitude / Planet.ceiling)) : 0
            // Where the moon was when it was chosen: the flight starts there, not on the belt
            // as it rises off with the camera
            property var moon: null
            property real grown: 1 // how big the moons were drawn then

            Connections {
                target: Skies

                function onHomingChanged() {
                    homing.grown = stage.moonScale;
                    homing.moon = Skies.homing ? Skies.placeOf(Skies.chosenAt, stage.planetCenter, Theme.skyBelt * stage.planetRadius * stage.unit, stage.unit, stage.moonScale, stage.width / stage.height) : null;
                }
            }
            // Where the control is on your page, as the page stands now
            readonly property point home: {
                const from = Skies.request?.from ?? Qt.point(stage.width / 2, stage.height / 2);
                const zoom = Math.exp(Math.log(Theme.orbitCard) * Planet.altitude);
                const lift = (stage.planetTop * stage.unit - stage.height) * stage.climbed;
                return Qt.point(stage.width / 2 + (from.x - stage.width / 2) * zoom, stage.height + (from.y - stage.height) * zoom + lift);
            }

            function span(from, to) {
                return Math.max(0, Math.min(1, (u - from) / (to - from)));
            }

            anchors.fill: parent
            visible: Skies.homing && moon !== null && u < 1

            // The moon itself folds back into its star, in its own colour, and flies
            SkyMoon {
                readonly property real fold: homing.span(0, 0.3)
                readonly property real fly: homing.span(0.2, 0.9)
                // Its size at the edge, so it can shrink to a 16 px star
                readonly property real base: homing.moon ? homing.moon.halfHeight / homing.grown : 1

                entry: Skies.items[Skies.chosen] ?? null
                offset: Skies.chosenAt
                center: homing.moon ? Qt.point(homing.moon.x + (homing.home.x - homing.moon.x) * (1 - Math.cos(Math.PI * fly)) / 2, homing.moon.y + (homing.home.y - homing.moon.y) * fly * fly * fly) : Qt.point(0, 0)
                radius: 0
                unit: stage.unit
                screenAspect: stage.width / stage.height
                grow: homing.grown + (16 / base - homing.grown) * fold * fold * fold // folded, a star is half its moon
                folded: fold
            }
        }

        // And it touches down
        StarRipple {
            id: touch
        }

        Connections {
            target: Planet

            function onAltitudeChanged() {
                if (Skies.homing && Planet.altitude === 0 && stage.focused)
                    touch.burst(homing.home.x, homing.home.y);
            }
        }

        SkyHands {
            anchors.fill: parent
            enabled: stage.lensHanded || Skies.looking // a moon being pulled down keeps its hand
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
            // Letting go of Space brings a sky you were looking at back up to its moon
            Keys.onReleased: event => {
                if (Planet.inSkies && event.key === Qt.Key_Space && !event.isAutoRepeat)
                    Skies.look(false);
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

        // A settings page drawn offscreen, to check it without opening the window
        Item {
            opacity: 0

            // On the window's own background, with its left margin
            Rectangle {
                id: pageFrame

                width: 800
                height: (pageCheck.item?.height ?? 0) + 20
                color: Theme.cardDeep

                Loader {
                    id: pageCheck

                    property string path: ""

                    x: 20
                    y: 10
                    width: 760
                    active: false
                    onLoaded: grabLater.restart()

                    Timer {
                        id: grabLater

                        interval: 400
                        onTriggered: pageFrame.grabToImage(result => {
                            console.info(`ETEA settings grab: ${result.saveToFile(pageCheck.path) ? pageCheck.path : "failed"}`);
                            pageCheck.active = false;
                        })
                    }
                }
            }
        }

        Connections {
            target: Menus

            function onPageWanted(page, path) {
                if (!stage.focused)
                    return;
                pageCheck.path = path;
                pageCheck.source = Qt.resolvedUrl(`../settings/${page}`);
                pageCheck.active = true;
            }
        }

        Connections {
            target: Skies

            function onGrabWanted(path) {
                if (stage.focused)
                    scene.grabToImage(result => console.info(`ETEA grab: ${result.saveToFile(path) ? path : "failed"}`));
                // What flies over the scene, kept apart
                if (stage.focused && homing.visible)
                    homing.grabToImage(result => result.saveToFile(path.replace(/\.png$/, "-over.png")));
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
