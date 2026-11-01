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
        readonly property real planetRadius: Math.exp(Math.log(Theme.terrainCurve) + (Math.log(Theme.orbitRadius) - Math.log(Theme.terrainCurve)) * Planet.altitude)
        readonly property real planetTop: {
            const ground = screenHeight * (1 - Theme.terrainHeight);
            const t = Math.max(0, Math.min(1, (Planet.altitude - 0.3) / 0.7));
            return ground + (screenHeight / 2 - Theme.orbitRadius - ground) * t * t * (3 - 2 * t);
        }

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "etea:stage"
        WlrLayershell.keyboardFocus: Planet.orbiting ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Empty region: clicks and keys go straight through, even mid-spin.
        // Up in orbit it's the other way round, the whole screen listens.
        property Region passThrough: Region {}
        property Region everything: Region {
            width: stage.width
            height: stage.height
        }

        mask: Planet.orbiting ? everything : passThrough

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
            anchors.fill: parent
            opacity: stage.showing ? Planet.sceneOpacity : 0
            // Fade as one flat picture, or the sky would shine through the windows
            layer.enabled: stage.showing

            World {
                anchors.fill: parent
                angle: Planet.resting + Planet.travel - Planet.handTurn
                radius: stage.planetRadius
                horizon: stage.planetTop / stage.screenHeight
                space: Math.min(1, Planet.altitude * 1.6)
                groundOpacity: 1 - Planet.systemLevel
            }

            // Your pages, standing around the planet
            Repeater {
                model: Planet.orbitPages

                StagePage {
                    opacity: 1 - Planet.systemLevel
                    required property var modelData
                    required property int index

                    anchors.fill: parent
                    windows: stage.focused ? modelData : []
                    photo: Planet.layouts[index + 1] === Planet.layoutOf(modelData) ? photos.itemAt(index)?.frame ?? null : null
                    pivotY: (stage.planetTop + stage.planetRadius) * stage.unit
                    screenX: stage.modelData.x
                    screenY: stage.modelData.y
                    angle: Planet.shortestSteps(Planet.origin, index + 1) * Planet.step - Planet.travel + Planet.handTurn
                    zoom: Math.exp(Math.log(Theme.orbitCard) * Planet.altitude)
                    lift: (stage.planetTop * stage.unit - stage.height) * Planet.altitude
                    orbitCard: true
                    pointedAt: Planet.hoveredPage === index
                }
            }

            StagePage {
                anchors.fill: parent
                windows: stage.focused ? Planet.leaving : []
                photo: photos.itemAt(Planet.origin - 1)?.frame ?? null
                pivotY: stage.pivotY
                screenX: stage.modelData.x
                screenY: stage.modelData.y
                angle: -Planet.travel
            }

            StagePage {
                anchors.fill: parent
                windows: stage.focused ? Planet.arriving : []
                photo: Planet.arrivalKnown ? photos.itemAt(Planet.target - 1)?.frame ?? null : null
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
            lift: (stage.planetTop * stage.unit - stage.height) * Planet.altitude
            screenX: stage.modelData.x
            screenY: stage.modelData.y
        }

        ThemeSystem {
            anchors.fill: parent
        }

        AtmosphereEntry {
            anchors.fill: parent
        }

        // In orbit: Escape goes down a level, 1 to 6 land on a page.
        // Up in the system: left and right pick a planet, Enter lands on it.
        Item {
            focus: Planet.orbiting
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    Planet.goDown();
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
                else if (!Planet.inSystem && event.key >= Qt.Key_1 && event.key < Qt.Key_1 + Config.pages)
                    Planet.leaveOrbit(event.key - Qt.Key_0);
            }
        }

        // Counts the frames of each spin, so we know if it's really smooth
        FrameAnimation {
            id: meter

            property real startedAt: 0

            running: stage.focused && Planet.phase === Planet.Phase.Spinning
            onRunningChanged: {
                if (running)
                    startedAt = Date.now();
                else if (currentFrame > 1)
                    console.info(`ETEA spin: ${currentFrame} frames in ${Date.now() - startedAt} ms, ${Math.round(currentFrame * 1000 / (Date.now() - startedAt))} fps`);
            }
        }

        Connections {
            target: Planet

            function onPhotoNeeded(page) {
                if (stage.focused)
                    photos.itemAt(page - 1)?.capture();
            }

            function onFinished(prepareMs) {
                if (stage.focused)
                    console.info(`ETEA ready: ${prepareMs} ms after the key press, ${Planet.captured}/${Planet.expected} captures`);
            }
        }
    }
}
