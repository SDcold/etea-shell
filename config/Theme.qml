pragma Singleton

import QtQuick
import Quickshell

// The whole look of ETEA lives here. Later on, every planet gets its own.
Singleton {
    readonly property var planet: Planets.find(Config.preview || Config.theme)
    readonly property real pace: Config.pace === "ceremony" ? 1.7 : 1 // stretches the big movements

    // That sunset from the mockup, plus the grain that gives it some texture
    readonly property color skyTop: planet.skyTop
    readonly property color skyMid: planet.skyMid
    readonly property color skyLow: planet.skyLow
    readonly property real grain: 0.34

    // The hills, from the farthest to the closest
    readonly property var terrainLayers: planet.terrain
    readonly property real terrainHeight: Config.terrainHeight // share of the screen height
    readonly property real terrainRelief: Config.terrainRelief // 0 is smooth, 1 is normal, 2 gets pretty wild
    readonly property real terrainCurve: 3600 // planet radius, on a 1600 wide screen

    // Our stars: white when they shine, grey while they sleep
    readonly property color star: "#ffffff"
    readonly property color starGlow: planet.light
    readonly property color starAsleep: "#d8d2d4"
    readonly property color link: planet.light

    // The bar floats just below the edge of the screen
    readonly property int barHeight: 40
    readonly property int barGap: 8
    readonly property int barSide: 20
    readonly property int barGlowRoom: 32

    // Crisp white on the sky, with a warm glow around it
    readonly property color text: "#ffffff"
    readonly property color textSoft: "#e8dfd8"
    readonly property color textGlow: planet.light

    // One font for the whole shell, icons on the side
    readonly property string font: "Poppins"
    readonly property int textSize: 14

    // The everyday pace: quick enough to never keep you waiting
    readonly property int fast: 160
    readonly property int normal: 280
    readonly property int pageSpin: 380 * pace
    readonly property int pageReveal: 90

    // The focused window catches the light, the others fall back into the shade
    readonly property color windowLit: planet.light
    readonly property real windowGlow: Config.windowGlow
    readonly property int windowGlowSize: Config.windowGlowSize
    readonly property int windowGlowPower: 4 // 1 is a flat band, 4 fades away like a star's halo
    readonly property real windowRestBorder: 0.12
    readonly property color windowRestShadow: "#000000"
    readonly property real windowRestShadowAlpha: 0.2
    readonly property real windowDim: Config.windowDim
    readonly property real windowFocusSpeed: 6 // Hyprland's unit, 1 is a tenth of a second

    // Hyprland draws the rounded frame, so it never lags behind the window
    readonly property int windowRadius: 22
    readonly property int windowGapOuter: Config.windowGapOuter // breathing room so the glow shows all the way around
    readonly property int windowGapInner: 5
    readonly property int traceWidth: Config.traceWidth // thickness of the frame
    readonly property real traceLine: 0.7

    // The stars sitting on the frame
    readonly property real traceCornerStar: 10
    readonly property real traceEdgeStar: 7
    readonly property real traceStarScale: 1 // scales all of them at once
    readonly property int traceFullSizeAt: 480 // windows narrower than this get smaller stars
    readonly property int traceSpacing: Config.traceSpacing // roughly one star every this many pixels
    readonly property int frameSlide: 300 // matches how long Hyprland takes to slide windows

    // A window closing: it folds into a star, then the star flies back to the bar
    readonly property int closeFold: 280 * pace
    readonly property int closeFlight: 340 * pace
    readonly property real closeStarSize: 16

    // A window opening: a star flares up, then opens onto the window
    readonly property int openPhotoEvery: 300 // how often we refresh the photo that freezes the screen
    readonly property int openSpark: 40
    readonly property int openReveal: 420 * pace
    readonly property int openMakeRoom: 340 // how long neighbours take to slide aside, hidden behind the photo
    readonly property string windowMoveCurve: "emphasizedDecel" // Hyprland's usual curve for moving windows
    readonly property int openCover: 200 // how long Hyprland hides a new window while the screen freezes

    // Going up: the ground curves away until it's a planet with your pages around it
    readonly property int orbitRise: 760 * pace
    readonly property real orbitRadius: 190 // size of the planet, on a 1600 wide screen
    readonly property real orbitCard: 0.145 // how small a page gets up there

    // The launcher: a dimmed sky, a question and a constellation of apps
    readonly property color launcherShade: "#05060e"
    readonly property real launcherDim: 0.72
    readonly property int launcherFade: 180
    readonly property int launcherSpacing: 170 // distance between two stars

    // Notifications: comets that land and open up
    readonly property color cardDeep: "#0d0f1c"

    // Colours a card can take when its content has none of its own
    readonly property var tones: ["#ffc98a", "#f59a7a", "#e98fb0", "#b9a2f0", "#8fc7e8", "#8fd6b4"]

    // Motion that overshoots a touch, then settles
    readonly property var expressive: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property int cardOpen: 340 * pace
    readonly property int notifWidth: 380
    readonly property int notifComet: 360
    readonly property int notifOpen: 240
    readonly property int notifLife: 6000 // how long one stays when the app doesn't say

    // The ground moving with the music
    readonly property real groundLift: Config.groundLift // how high the ridges can climb, on a 1600 wide screen
    readonly property real groundSettle: 0.05 // how fast it calms down when the music stops, lower is slower

    // The side panels
    readonly property int panelWidth: 420

    // How thick progress bars and rings are
    readonly property int barThickness: 7
    readonly property int ringThickness: 6

    // What's written directly on the sky, close to white with a touch of the planet's light
    readonly property color skyInk: Qt.tint(windowLit, Qt.alpha("#ffffff", 0.7))

    // Where things sit in the bar, so stars know where to fly
    readonly property int pageWidth: 66
    readonly property int pageGap: 8

    // We bring our own font so nobody has to install anything
    Instantiator {
        model: ["Light", "Regular", "Medium", "SemiBold"]

        FontLoader {
            required property string modelData

            source: "file://" + Quickshell.shellPath(`assets/fonts/Poppins-${modelData}.ttf`)
        }
    }
}
