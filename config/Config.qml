pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Everything people can change. It lives in ~/.config/etea/settings.json, the settings
// page writes it for you, and editing the file by hand works too.
Singleton {
    id: root

    readonly property int pages: 6
    readonly property string locale: "fr_FR"
    readonly property int launcherStars: 7 // how many apps the launcher shows at once

    readonly property var statusChoices: [
        { id: "tray", label: "Applis en arrière-plan" },
        { id: "notifications", label: "Notifications" },
        { id: "network", label: "Réseau" },
        { id: "bluetooth", label: "Bluetooth" },
        { id: "volume", label: "Volume" },
        { id: "battery", label: "Batterie" },
        { id: "settings", label: "Réglages" },
        { id: "session", label: "Session" }
    ]

    property string preview: "" // a world being tried on, never saved
    property alias theme: saved.theme
    property alias customPlanets: saved.customPlanets
    property alias pace: saved.pace // "daily" is quick, "ceremony" takes its time
    property alias status: saved.status
    property alias widgets: saved.widgets
    property alias widgetStyle: saved.widgetStyle // "sky" or "celestial"
    property alias decorations: saved.decorations
    property alias groundMusic: saved.groundMusic // "lines", "bars" or "off"
    property alias groundLift: saved.groundLift
    property alias terrainHeight: saved.terrainHeight
    property alias terrainRelief: saved.terrainRelief
    property alias windowGlow: saved.windowGlow
    property alias windowGlowSize: saved.windowGlowSize
    property alias windowDim: saved.windowDim
    property alias traceWidth: saved.traceWidth
    property alias traceSpacing: saved.traceSpacing
    property alias windowGapOuter: saved.windowGapOuter

    // The folder has to exist before we can save anything into it
    Process {
        running: true
        command: ["mkdir", "-p", `${Quickshell.env("HOME")}/.config/etea`]
    }

    // Dragging a slider changes things constantly, so wait for it to settle before saving
    Timer {
        id: saveSoon

        interval: 400
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file

        path: `${Quickshell.env("HOME")}/.config/etea/settings.json`
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: saveSoon.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                saveSoon.restart();
        }

        JsonAdapter {
            id: saved

            property string theme: "aster"
            property var customPlanets: []
            property string pace: "daily"
            property var status: ["tray", "notifications", "network", "bluetooth", "volume", "battery", "settings", "session"]

            // Widgets in the sky, for when a page is empty. x and y are shares of the screen.
            property var widgets: [
                { type: "clock", x: 0.5, y: 0.34, shown: true },
                { type: "system", x: 0.14, y: 0.3, shown: true },
                { type: "media", x: 0.84, y: 0.3, shown: true }
            ]

            // Images from decorations/, placed in the sky behind the terrain. x, y and
            // width are shares of the screen, opacity and rotation are optional.
            // Example: { file: "comet.svg", x: 0.2, y: 0.3, width: 0.1, opacity: 0.8, rotation: -12 }
            property var decorations: []

            property string widgetStyle: "sky"
            property string groundMusic: "lines"
            property real groundLift: 96
            property real terrainHeight: 0.089
            property real terrainRelief: 1
            property real windowGlow: 0.34
            property int windowGlowSize: 34
            property real windowDim: 0.28
            property int traceWidth: 2
            property int traceSpacing: 420
            property int windowGapOuter: 12
        }
    }
}
