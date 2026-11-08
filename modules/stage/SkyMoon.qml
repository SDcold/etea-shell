import QtQuick
import qs.config
import qs.services

// One moon of the belt: the world its picture would make. The picture cropped as the
// screen would crop it, four flat hills in the colours it would give, a ring inked in its
// own light, and one flat star asleep on top. Until its thumbnail is in, it's a star in its
// cached colour, which rounds into the moon as the picture lands.
Item {
    id: root

    property var entry: null // what it shows, from Skies.items
    property real offset: 0 // how far from the zenith it hangs, in moons
    property point center // the planet's centre, and the belt's radius round it, in pixels
    property real radius: 0
    property real grow: 1 // moons grow and shrink with the planet
    property bool hovered: false
    property real unit: 1
    property real screenAspect: 16 / 9

    // Where it hangs and what shape it takes there, as Skies.placeOf works it out. Plain
    // numbers, worked out every frame of a turn without making anything for the collector.
    readonly property real phi: (11 * offset + 3.5 * Math.tanh(11 * offset / 7)) * Math.PI / 180
    // 0 on the belt, 1 opened into the porthole at the zenith
    readonly property real opening: {
        const t = Math.min(1, Math.abs(offset));
        return 1 - t * t * (3 - 2 * t);
    }
    readonly property real halfHeight: (Theme.moonSize / 2 + (Theme.portholeWidth / 2 / screenAspect - Theme.moonSize / 2) * opening) * grow * unit * lift
    readonly property real aspect: 1 + (screenAspect - 1) * opening
    // Under the pointer it lifts a little, and its star lights
    property real lift: hovered ? 1.06 : 1

    Behavior on lift {
        NumberAnimation { duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
    }
    readonly property real exponent: 2 + 2.6 * opening
    property real rise: 1 // how far its hills have risen
    property real inked: 1 // how much of its ring and star are drawn
    property bool lit: hovered || opening > 0.5 // the zenith's star is lit, the others sleep
    readonly property var palette: (Palettes.version, Skies.paletteOf(entry))
    readonly property bool picture: !!entry?.path
    readonly property real starSize: (4.5 + 3 * opening) * unit
    readonly property real margin: 10 * unit + starSize

    // The thumbnails tried in turn: the system's x-large, its large, ours, then the picture
    property int stage: 0
    readonly property var picked: picture ? Pictures.pictures.find(p => p.path === entry.path) ?? { path: entry.path, mtime: entry.mtime } : null

    x: center.x + radius * Math.sin(phi) - width / 2
    y: center.y - radius * Math.cos(phi) - height / 2
    width: 2 * (halfHeight * aspect + margin)
    height: 2 * (halfHeight + margin)

    // In, it rounds from its star into the moon; recycled to a picture not in yet, it's a star again
    readonly property bool loaded: !picture || thumbnail.status === Image.Ready

    onEntryChanged: stage = picked ? Pictures.firstStage(picked) : 0
    onLoadedChanged: {
        if (loaded) {
            ready.restart();
        } else {
            ready.stop();
            shape.ready = 0;
        }
    }
    Component.onCompleted: shape.ready = loaded ? 1 : 0

    Image {
        id: thumbnail

        visible: false
        asynchronous: true
        mipmap: true
        sourceSize.width: 512
        source: root.picked ? Pictures.thumb(root.picked, root.stage) : ""
        onStatusChanged: {
            if (status === Image.Error && root.stage < 3)
                root.stage += 1;
        }
    }

    ShaderEffect {
        id: shape

        property real ready: 1

        anchors.fill: parent

        property color skyTop: root.palette?.skyTop ?? Theme.skyTop
        property color skyMid: root.palette?.skyMid ?? Theme.skyMid
        property color skyLow: root.palette?.skyLow ?? Theme.skyLow
        property color terrain0: root.palette?.terrain[0] ?? dominant
        property color terrain1: root.palette?.terrain[1] ?? dominant
        property color terrain2: root.palette?.terrain[2] ?? dominant
        property color terrain3: root.palette?.terrain[3] ?? dominant
        property color light: root.palette?.light ?? Theme.windowLit
        property color dominant: (Palettes.version, Skies.dominantOf(root.entry))
        property color night: Theme.launcherShade
        property vector2d size: Qt.vector2d(width, height)
        property vector2d pictureSize: Qt.vector2d(thumbnail.implicitWidth, thumbnail.implicitHeight)
        property real halfHeight: root.halfHeight
        property real aspect: root.aspect
        property real exponent: root.exponent
        property real rise: root.rise
        property real kind: root.picture ? 0 : root.entry?.special === "world" ? 1 : 2
        property real porthole: root.opening
        property real screenAspect: root.screenAspect
        property real unit: root.unit
        property real rough: Skies.planet.rough ?? 1
        property real gap: root.starSize + 4 * root.unit
        property real seed: Skies.seedOf(root.entry)
        property real grain: Theme.grain
        property real inked: root.inked
        property real starSize: root.starSize
        property real starLit: root.lit ? 1 : 0
        property var picture: thumbnail

        Behavior on starLit {
            NumberAnimation { duration: 160 }
        }

        fragmentShader: Qt.resolvedUrl("../../shaders/moon.frag.qsb")

        NumberAnimation on ready {
            id: ready

            running: false
            to: 1
            duration: 240
        }
    }
}
