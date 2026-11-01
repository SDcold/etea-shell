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

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "etea:stage"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Empty region: clicks and keys go straight through, even mid-spin
        mask: Region {}

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
                angle: Planet.resting + Planet.travel
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
            active: stage.focused && Planet.phase !== Planet.Phase.Spinning
        }

        WindowBirth {
            anchors.fill: parent
            screenX: stage.modelData.x
            screenY: stage.modelData.y
            active: stage.focused
        }

        WindowExit {
            anchors.fill: parent
            output: stage.modelData
            screenX: stage.modelData.x
            screenY: stage.modelData.y
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
