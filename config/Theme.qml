pragma Singleton

import QtQuick
import Quickshell

// The whole look of ETEA lives here. Later on, every planet gets its own.
Singleton {
    // That sunset from the mockup, plus the grain that gives it some texture
    readonly property color skyTop: "#2b3a55"
    readonly property color skyMid: "#c9744b"
    readonly property color skyLow: "#f2b872"
    readonly property real grain: 0.34

    // The hills, from the farthest to the closest
    readonly property var terrainLayers: ["#a8553c", "#7a3a33", "#4f2630", "#2c1622"]
    readonly property real terrainHeight: 0.089 // share of the screen height
    readonly property real terrainRelief: 1 // 0 is smooth, 1 is normal, 2 gets pretty wild
    readonly property real terrainCurve: 3600 // planet radius, on a 1600 wide screen

    // Our stars: white when they shine, grey while they sleep
    readonly property color star: "#ffffff"
    readonly property color starGlow: "#ffe2a8"
    readonly property color starAsleep: "#d8d2d4"
    readonly property color link: "#ffe2a8"

    // The bar floats just below the edge of the screen
    readonly property int barHeight: 40
    readonly property int barGap: 8
    readonly property int barSide: 20
    readonly property int barGlowRoom: 32

    // Crisp white on the sky, with a warm glow around it
    readonly property color text: "#ffffff"
    readonly property color textSoft: "#e8dfd8"
    readonly property color textGlow: "#ffe2a8"

    // One font for the whole shell, icons on the side
    readonly property string font: fontLoader.name
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property int textSize: 16

    // The everyday pace: quick enough to never keep you waiting
    readonly property int fast: 160
    readonly property int normal: 280
    readonly property int pageSpin: 380
    readonly property int pageReveal: 90

    // The focused window catches the light, the others fall back into the shade
    readonly property color windowLit: "#ffe2a8"
    readonly property real windowGlow: 0.34
    readonly property int windowGlowSize: 34
    readonly property int windowGlowPower: 4 // 1 is a flat band, 4 fades away like a star's halo
    readonly property real windowRestBorder: 0.12
    readonly property color windowRestShadow: "#000000"
    readonly property real windowRestShadowAlpha: 0.2
    readonly property real windowDim: 0.28
    readonly property real windowFocusSpeed: 6 // Hyprland's unit, 1 is a tenth of a second

    // Hyprland draws the rounded frame, so it never lags behind the window
    readonly property int windowRadius: 22
    readonly property int windowGapOuter: 12 // breathing room so the glow shows all the way around
    readonly property int windowGapInner: 5
    readonly property int traceWidth: 2 // thickness of the frame
    readonly property real traceLine: 0.7

    // The stars sitting on the frame
    readonly property real traceCornerStar: 10
    readonly property real traceEdgeStar: 7
    readonly property real traceStarScale: 1 // scales all of them at once
    readonly property int traceFullSizeAt: 480 // windows narrower than this get smaller stars
    readonly property int traceSpacing: 420 // roughly one star every this many pixels
    readonly property int frameSlide: 300 // matches how long Hyprland takes to slide windows

    // A window closing: it folds into a star, then the star flies back to the bar
    readonly property int closeFold: 280
    readonly property int closeFlight: 340
    readonly property real closeStarSize: 16

    // Where things sit in the bar, so stars know where to fly
    readonly property int pageWidth: 66
    readonly property int pageGap: 8

    // We bring our own font so nobody has to install anything
    property FontLoader fontLoader: FontLoader {
        source: "file://" + Quickshell.shellPath("assets/fonts/Federo.ttf")
    }
}
