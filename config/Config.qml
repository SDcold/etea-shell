pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Everything people can change. It lives in ~/.config/etea/settings.json, the settings
// page writes it for you, and editing the file by hand works too.
Singleton {
    id: root

    // Pages come in groups: the bar shows one group, the planet carries one group around it.
    // Past the last page of a group, the next group takes its place.
    readonly property int pages: Math.max(4, Math.min(10, pagesShown))
    readonly property string locale: Lang.locale
    readonly property int launcherStars: 7 // how many apps the launcher shows at once

    // What the bar can hold, and where each piece can go
    readonly property var barModuleChoices: [
        { id: "pages", label: Lang.t("Pages"), icon: "layout" },
        { id: "clock", label: Lang.t("Heure"), icon: "timer" },
        { id: "media", label: Lang.t("Musique"), icon: "music" },
        { id: "tray", label: Lang.t("Plateau"), icon: "apps" },
        { id: "status", label: Lang.t("Statut"), icon: "wifi-high" },
        { id: "tools", label: Lang.t("Outils"), icon: "picker" },
        { id: "resources", label: Lang.t("Ressources"), icon: "cpu" }
    ]
    readonly property var toolChoices: [
        { id: "capture", label: Lang.t("Capture"), icon: "capture" },
        { id: "clipboard", label: Lang.t("Presse-papiers"), icon: "clipboard" },
        { id: "picker", label: Lang.t("Pipette"), icon: "picker" },
        { id: "nightlight", label: Lang.t("Veilleuse"), icon: "nightlight" },
        { id: "microphone", label: Lang.t("Micro"), icon: "microphone" }
    ]
    readonly property var resourceChoices: [
        { id: "cpu", label: Lang.t("Processeur"), icon: "cpu" },
        { id: "memory", label: Lang.t("Mémoire"), icon: "ram" },
        { id: "network", label: Lang.t("Débit réseau"), icon: "speed" }
    ]

    readonly property var statusChoices: [
        { id: "notifications", label: "Notifications", icon: "bell" },
        { id: "network", label: Lang.t("Réseau"), icon: "wifi-high" },
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" },
        { id: "volume", label: "Volume", icon: "speaker-high" },
        { id: "battery", label: Lang.t("Batterie"), icon: "battery-full" },
        { id: "settings", label: Lang.t("Réglages"), icon: "gear-six" },
        { id: "session", label: Lang.t("Session"), icon: "power" }
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

    property alias language: saved.language // "auto" follows the system, or a code from Lang.languages
    property alias pagesShown: saved.pagesShown
    property alias lockImage: saved.lockImage // a picture for the lock's first page, empty shows the landscape
    property alias barPosition: saved.barPosition // "top" or "bottom"
    property alias barSize: saved.barSize // "compact", "normal" or "large"
    property alias barStyle: saved.barStyle // "sky", "islands" or "band"
    property alias barLayout: saved.barLayout // { left, center, right }, each a list of modules
    property alias barTools: saved.barTools
    property alias barResources: saved.barResources
    property alias clockFormat: saved.clockFormat // "24" or "12"
    property alias clockSeconds: saved.clockSeconds
    property alias dateFormat: saved.dateFormat // "long", "short" or "off"
    property alias barPercent: saved.barPercent // numbers beside the volume and battery
    property alias mediaTitle: saved.mediaTitle // "scroll", "short" or "off"
    property alias hotCorners: saved.hotCorners
    property alias pageStyle: saved.pageStyle // "constellation" or "numbers"
    property alias trayTint: saved.trayTint // background apps drawn in the shell's colours

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
            property var status: ["notifications", "network", "bluetooth", "volume", "battery", "settings", "session"]

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

            property string language: "auto"
            property int pagesShown: 8
            property string lockImage: ""
            property string barPosition: "top"
            property string barSize: "normal"
            property string barStyle: "sky"
            property var barLayout: ({ left: ["pages"], center: ["clock", "media"], right: ["tray", "status"] })
            property var barTools: ["capture", "clipboard", "picker"]
            property var barResources: ["cpu", "memory"]
            property string clockFormat: "24"
            property bool clockSeconds: false
            property string dateFormat: "long"
            property bool barPercent: true
            property string mediaTitle: "scroll"
            property bool hotCorners: true
            property string pageStyle: "constellation"
            property bool trayTint: false
        }
    }
}
