import QtQuick
import qs.config
import qs.services

// The music as light, brought over from end4-pC: veils of aurora, mirrored bars, a dot
// matrix or a halo around the screen along the bottom, or a ring of bars round the cover.
// The levels are cava's, through Beat; they rise fast, settle slowly, leave falling peaks
// and a pulse on each beat, and fade out when the music stops.
Item {
    id: root

    property string style: "veils" // "veils", "mirror", "dots", "halo" or "ring"
    property bool listening: true
    property color color1: "white"
    property color color2: "white"
    property color color3: "white"
    property real unit: width / 1600

    readonly property bool ring: style === "ring"
    readonly property bool frame: style === "halo"
    readonly property string shader: ({ veils: "viz-aurora", mirror: "viz-mirror", dots: "viz-dots", halo: "viz-halo", ring: "viz-ring" })[style] ?? "viz-aurora"

    // What the shaders read: up to 52 bands, four to a vector
    readonly property int maxBands: 52
    property int bandCount: 0
    property real time: 0
    property real bass: 0
    property real fade: 0
    readonly property var levels: new Array(maxBands).fill(0)
    readonly property var peaks: new Array(maxBands).fill(0)
    readonly property var peakHold: new Array(maxBands).fill(0)
    property real lastSignal: 0
    property real bassAverage: 0

    readonly property bool hearing: listening && Beat.dancing && Beat.levels.length > 0

    // Quick to rise, slow to fall; a peak waits a moment, then drops; a beat is the lows
    // jumping well above their recent average
    function step(dt) {
        const source = Beat.levels;
        if (source.some(level => level > 0))
            lastSignal = Date.now();
        const playing = hearing && Date.now() - lastSignal < 1000;
        bandCount = Math.min(source.length || bandCount, maxBands);
        time += dt;
        fade += ((playing ? 1 : 0) - fade) * Math.min(1, dt * (playing ? 4 : 1.5));
        let low = 0;
        for (let i = 0; i < maxBands; i++) {
            const target = playing && i < source.length ? Math.min(1, source[i]) : 0;
            levels[i] += (target - levels[i]) * Math.min(1, dt * (target > levels[i] ? 18 : 5));
            if (levels[i] >= peaks[i]) {
                peaks[i] = levels[i];
                peakHold[i] = 0.35;
            } else if (peakHold[i] > 0) {
                peakHold[i] -= dt;
            } else {
                peaks[i] = Math.max(levels[i], peaks[i] - dt * 0.45);
            }
            if (i < 4)
                low += target / 4;
        }
        bassAverage += (low - bassAverage) * Math.min(1, dt * 1.5);
        if (low > bassAverage * 1.3 + 0.04 && low > 0.25)
            bass = Math.min(1, bass + (low - bassAverage) * 2.5);
        bass *= Math.exp(-dt * 5);
        for (let k = 0; k < 13; k++) {
            const i = k * 4;
            light[`b${k}`] = Qt.vector4d(levels[i], levels[i + 1], levels[i + 2], levels[i + 3]);
            light[`p${k}`] = Qt.vector4d(peaks[i], peaks[i + 1], peaks[i + 2], peaks[i + 3]);
        }
    }

    // Ticks at the screen's rate only while there's something to show
    FrameAnimation {
        running: root.visible && (root.hearing || root.fade > 0.002)
        onTriggered: root.step(Math.min(frameTime, 0.1))
    }

    // The ring's cover, rendered square for its shader
    Item {
        id: coverItem

        width: 512
        height: 512
        visible: false
        layer.enabled: root.ring

        Image {
            id: coverImage

            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(512, 512)
            source: root.ring ? Music.player?.trackArtUrl ?? "" : ""
        }
    }

    ShaderEffect {
        id: light

        // Along the bottom; the halo frames the whole screen; the ring stands low in the middle
        readonly property real ringSize: Math.round(root.height * 0.36)
        x: root.ring ? (root.width - ringSize) / 2 : 0
        y: root.ring ? root.height - ringSize - Math.round(root.height * 0.06) : root.frame ? 0 : root.height - height
        width: root.ring ? ringSize : root.width
        height: root.ring ? ringSize : root.frame ? root.height : Math.round(root.height * 0.24)
        visible: root.fade > 0.002
        blending: true

        property real time: root.time
        property real bass: root.bass
        property real fade: root.fade
        property vector2d resolution: Qt.vector2d(width, height)
        property real bandCount: root.bandCount
        property real hasCover: coverImage.status === Image.Ready ? 1 : 0
        property color color1: root.color1
        property color color2: root.color2
        property color color3: root.color3
        property var cover: coverItem
        property vector4d b0; property vector4d b1; property vector4d b2; property vector4d b3
        property vector4d b4; property vector4d b5; property vector4d b6; property vector4d b7
        property vector4d b8; property vector4d b9; property vector4d b10; property vector4d b11
        property vector4d b12
        property vector4d p0; property vector4d p1; property vector4d p2; property vector4d p3
        property vector4d p4; property vector4d p5; property vector4d p6; property vector4d p7
        property vector4d p8; property vector4d p9; property vector4d p10; property vector4d p11
        property vector4d p12

        fragmentShader: Qt.resolvedUrl(`../../shaders/${root.shader}.frag.qsb`)
    }
}
