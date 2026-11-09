import QtQuick
import Quickshell
import qs.config
import qs.modules.widgets
import qs.services

// Stack the sky, the decorations, the widgets, then the terrain so it sits in front.
Item {
    id: root

    property real angle: 0 // how far the planet has turned
    property real radius: Theme.terrainCurve // shrink it and the ground becomes a planet
    property real horizon: 1 - Theme.terrainHeight
    property real space: 0
    property real groundOpacity: 1
    property bool showWidgets: true
    property bool interactive: false // only the real desktop answers the pointer
    // Keep the sky and the ground as pictures while they hold still, so a widget moving in
    // front doesn't make the GPU paint them again pixel by pixel. Off where they move every frame.
    property bool cached: true
    property bool listening: true // the ground dances to the music; a small preview stays still
    property real arrival: Planet.arrival
    // The world drawn: the one you live on, or any other to look at it
    property var planet: Theme.planet
    property string skyImage: planet.sky ?? ""
    property bool ground: planet.ground ?? true
    // Up at the edge of the air: night and your air in bands behind, and your own sky in a
    // lens, folding from the whole screen into a porthole. { x, y, reach, exponent, aspect }
    // in pixels, or nothing to draw the sky as usual.
    property var lens: null
    readonly property bool edge: lens !== null
    // What hangs at the edge of the air, between the night and your sky: the belt of skies
    property Component belt: null
    // A sky tried on up there: { shown, next, x, y, reach }. The air and the planet wear
    // `shown`, and `next` sweeps over them as ETEA's star from x, y, as far as reach.
    property var tryOn: null
    readonly property var dress: tryOn?.shown ?? planet
    // A new day on this world: outside the dawn's edge the old colours, inside the new
    // (for a dusk the other way round), rising from under the horizon at the sun's place
    readonly property bool morphing: Morph.busy && Morph.from !== null && Morph.planetId === planet.id
    readonly property var tintA: morphing ? (Morph.dusk ? Morph.to : Morph.from) : dress
    readonly property var tintB: morphing ? (Morph.dusk ? Morph.from : Morph.to) : dress
    readonly property point dawnFrom: Qt.point(width * (planet.sun ?? 0.25), height * horizon + height * 0.12)
    // A new form for the ground, running in from where it was touched, and the land sinking
    readonly property bool reshaping: morphing && Morph.reshaped
    readonly property bool sinking: morphing && Morph.sinking
    readonly property bool restaging: morphing && Morph.restaged
    readonly property var formA: reshaping ? Morph.from : planet
    readonly property var formB: reshaping ? Morph.to : planet
    readonly property real dawnEdge: {
        if (!morphing)
            return 0;
        const across = Math.max(dawnFrom.x, width - dawnFrom.x) / 2.6;
        const reach = Math.hypot(across, dawnFrom.y) + 4;
        return reach * (Morph.dusk ? 1 - Morph.tint : Morph.tint);
    }
    readonly property var sweeping: tryOn?.next ?? null
    readonly property real unit: width / 1600
    readonly property point center: Qt.point(width / 2, height * horizon + radius * unit)

    // Four sound levels at a time, the way the shader wants them. Only read while the ground
    // dances: otherwise every level another listener hears would redraw the cached hills.
    function bands(first) {
        if (!(terrain.music > 0))
            return Qt.vector4d(0, 0, 0, 0);
        const levels = Beat.shown;
        return Qt.vector4d(levels[first] ?? 0, levels[first + 1] ?? 0, levels[first + 2] ?? 0, levels[first + 3] ?? 0);
    }

    ShaderEffect {
        anchors.fill: parent

        // Painted, or while your picture is still on its way
        visible: !root.edge && (root.skyImage === "" || pictureSource.status !== Image.Ready)

        property color colorTop: root.tintA.skyTop
        property color colorMid: root.tintA.skyMid
        property color colorLow: root.tintA.skyLow
        property color colorTopB: root.tintB.skyTop
        property color colorMidB: root.tintB.skyMid
        property color colorLowB: root.tintB.skyLow
        property vector2d dawnCenter: Qt.vector2d(root.dawnFrom.x, root.dawnFrom.y)
        property real dawnEdge: root.dawnEdge
        property real bandInside: Morph.dusk ? 0 : 1
        property color dawnLight: root.morphing ? Morph.to.light : "white"
        property vector2d resolution: Qt.vector2d(width, height)
        property real grain: Theme.grain
        property real space: root.space

        layer.enabled: root.cached && !root.morphing
        fragmentShader: Qt.resolvedUrl("../../shaders/sky.frag.qsb")
    }

    // Loaded just big enough to cover the screen, the shader does the cropping
    Image {
        id: pictureSource

        visible: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        source: root.skyImage ? Pictures.url(root.skyImage) : ""
    }

    ShaderEffect {
        anchors.fill: parent

        visible: !root.edge && root.skyImage !== "" && pictureSource.status === Image.Ready

        property var picture: pictureSource
        property vector2d pictureSize: Qt.vector2d(pictureSource.implicitWidth, pictureSource.implicitHeight)
        property vector2d resolution: Qt.vector2d(width, height)
        property real grain: Theme.grain
        property real space: root.space

        layer.enabled: root.cached && !root.morphing
        property vector2d dawnCenter: Qt.vector2d(root.dawnFrom.x, root.dawnFrom.y)
        property real dawnEdge: root.dawnEdge
        property real bandInside: Morph.dusk ? 0 : 1
        property color dawnLight: root.morphing ? Morph.to.light : "white"
        fragmentShader: Qt.resolvedUrl("../../shaders/skyimage.frag.qsb")
    }

    // Only built while up at the edge: the backgrounds never need any of it
    Loader {
        anchors.fill: parent
        active: root.edge

        sourceComponent: Item {
            ShaderEffect {
                anchors.fill: parent

                property color colorTop: root.dress.skyTop
                property color night: Theme.launcherShade
                property vector2d resolution: Qt.vector2d(width, height)
                property vector2d center: Qt.vector2d(root.center.x, root.center.y)
                property real radius: root.radius * root.unit
                property real edge: Theme.skyBelt * radius
                property real grain: Theme.grain
                property real drift: Skies.scroll * 14 * root.unit // the stars slide a little as the belt turns
                property color nextTop: root.sweeping?.skyTop ?? colorTop
                property color sweepLight: root.sweeping?.light ?? "white"
                property vector2d sweepCenter: root.sweeping ? Qt.vector2d(root.tryOn.x, root.tryOn.y) : Qt.vector2d(0, 0)
                property real sweepReach: root.sweeping ? root.tryOn.reach : 0

                fragmentShader: Qt.resolvedUrl("../../shaders/atmosphere.frag.qsb")
            }

            Loader {
                anchors.fill: parent
                sourceComponent: root.belt
            }

            // The sky in the lens: yours, or the one being looked at or landed. The same
            // picture at the same size as the background's, so it shares its decoding.
            Image {
                id: lensPicture

                visible: false
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(root.width, root.height)
                source: root.lens?.path ? Pictures.url(root.lens.path) : root.skyImage ? Pictures.url(root.skyImage) : ""
            }

            // And small, for when the lens is: the full one would shimmer down there
            Image {
                id: smallPicture

                visible: false
                asynchronous: true
                mipmap: true
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(512, Math.round(512 * root.height / Math.max(1, root.width)))
                source: root.lens?.thumb ? root.lens.thumb : root.lens?.path ? Pictures.url(root.lens.path) : root.skyImage ? Pictures.url(root.skyImage) : ""
            }

            ShaderEffect {
                // Only the lens's own box is drawn, once it no longer covers the screen
                readonly property real across: root.edge ? root.lens.reach : 0
                readonly property real down: root.edge ? root.lens.reach / root.lens.aspect : 0
                // Big, it shows the sky in place; small, the whole sky shrinks into it, as tall
                // as the lens, the way a moon shows it
                readonly property real shrink: Math.min(1, down / (root.height / 2))
                readonly property bool flat: root.lens?.painted ?? root.skyImage === ""
                readonly property var colours: root.lens?.palette ?? root.planet
                readonly property real toMiddle: Math.max(0, Math.min(1, (1 - shrink) / (1 - Theme.portholeWidth / 1600)))

                // with room around it for the ring and the star on top
                readonly property real room: 6 + (root.edge ? root.lens.starSize * 2 : 0)

                x: Math.max(0, Math.floor((root.edge ? root.lens.x : 0) - across - room))
                y: Math.max(0, Math.floor((root.edge ? root.lens.y : 0) - down - room))
                width: Math.min(root.width, Math.ceil((root.edge ? root.lens.x : 0) + across + room)) - x
                height: Math.min(root.height, Math.ceil((root.edge ? root.lens.y : 0) + down + room)) - y
                visible: root.edge && !root.lens.hidden && width > 0 && height > 0 && (flat || lensPicture.status === Image.Ready)

                property color colorTop: colours.skyTop
                property color colorMid: colours.skyMid
                property color colorLow: colours.skyLow
                property vector2d resolution: Qt.vector2d(root.width, root.height)
                property vector2d box: Qt.vector2d(x, y)
                property vector2d boxSize: Qt.vector2d(width, height)
                property vector2d pictureSize: Qt.vector2d(lensPicture.implicitWidth, lensPicture.implicitHeight)
                property vector2d smallSize: Qt.vector2d(smallPicture.implicitWidth, smallPicture.implicitHeight)
                property vector2d center: root.edge ? Qt.vector2d(root.lens.x, root.lens.y) : Qt.vector2d(0, 0)
                property vector2d anchor: Qt.vector2d(center.x + (root.width / 2 - center.x) * toMiddle, center.y + (root.height / 2 - center.y) * toMiddle)
                property real reach: across
                property real exponent: root.edge ? root.lens.exponent : 2
                property real aspect: root.edge ? root.lens.aspect : 1
                property real scale: shrink
                property real painted: flat ? 1 : 0
                property real grain: Theme.grain
                property var picture: lensPicture
                property var small: smallPicture
                property real smallReady: smallPicture.status === Image.Ready ? 1 : 0
                property color light: root.edge ? root.lens.light : "white"
                property real ring: root.edge ? root.lens.ring : 0
                property real starSize: root.edge ? root.lens.starSize : 0
                property real gap: root.edge ? root.lens.gap : 0
                property real seed: root.edge ? root.lens.seed : 0
                property real wobbly: root.edge ? root.lens.wobbly : 0
                property real starLit: root.edge ? root.lens.starLit : 0

                fragmentShader: Qt.resolvedUrl("../../shaders/skylens.frag.qsb")
            }
        }
    }

    // The world's own sky: its moons, its rings, its clouds. Gone once we've left the air.
    Scenery {
        anchors.fill: parent
        planet: root.restaging ? Morph.to : root.planet
        angle: root.angle
        horizon: root.horizon
        visible: root.space < 0.33
        opacity: 1 - root.space * 3
        // Coming into a world's sky, it rises from behind the far ridge
        transform: Translate {
            y: root.restaging ? (1 - Morph.rising) * root.height * 0.5 : 0
        }
    }

    // And what was there sets behind it, the way down a little faster
    Scenery {
        anchors.fill: parent
        planet: root.restaging ? Morph.from : root.planet
        angle: root.angle
        horizon: root.horizon
        visible: root.restaging && Morph.setting < 1 && root.space < 0.33
        opacity: 1 - root.space * 3
        transform: Translate {
            y: Morph.setting * root.height * 0.5
        }
    }

    // Everyone's own images, placed by proportion so they fit on any screen
    Repeater {
        model: Config.decorations

        Image {
            required property var modelData

            source: "file://" + Quickshell.shellPath("decorations/" + modelData.file)
            x: modelData.x * root.width - width / 2
            y: modelData.y * root.height - height / 2
            width: modelData.width * root.width
            height: width * (implicitHeight / Math.max(1, implicitWidth))
            sourceSize.width: width
            fillMode: Image.PreserveAspectFit
            opacity: modelData.opacity ?? 1
            rotation: modelData.rotation ?? 0
            smooth: true
        }
    }

    // Landing somewhere new: the same light that runs along the ridges writes the
    // planet's name on the sky, from the middle out, then it fades
    Item {
        readonly property real reveal: {
            const t = Math.max(0, Math.min(1, (root.arrival - 0.06) / 0.32));
            return 1 - (1 - t) * (1 - t);
        }

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * root.horizon - height - root.height * 0.13
        width: words.width * reveal
        height: words.height
        clip: true
        visible: root.arrival > 0 && root.space < 0.01
        opacity: 1 - Math.max(0, Math.min(1, (root.arrival - 0.78) / 0.22))

        Column {
            id: words

            x: (parent.width - width) / 2
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.planet.name
                color: Theme.skyInk
                font.family: Theme.font
                font.pixelSize: 44
                font.weight: Font.Light
                font.letterSpacing: 2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.planet.line
                color: Qt.alpha(Theme.skyInk, 0.75)
                font.family: Theme.font
                font.pixelSize: 16
            }
        }
    }

    Widgets {
        anchors.fill: parent
        interactive: root.interactive
        opacity: 1 - root.space * 3
        visible: root.showWidgets && opacity > 0
    }

    ShaderEffect {
        id: terrain

        anchors.fill: parent

        // Without hills, only the music stays on the ground until it has become a planet
        opacity: root.groundOpacity
        property real hills: root.ground || root.sinking ? 1 : Math.min(1, root.space * 3)
        visible: opacity > 0

        // planetAngle is what will spin the planet between pages
        property color layer0: root.tintA.terrain[0]
        property color layer1: root.tintA.terrain[1]
        property color layer2: root.tintA.terrain[2]
        property color layer3: root.tintA.terrain[3]
        property color layerB0: root.tintB.terrain[0]
        property color layerB1: root.tintB.terrain[1]
        property color layerB2: root.tintB.terrain[2]
        property color layerB3: root.tintB.terrain[3]
        property color rimB: root.tintB.skyLow
        property vector2d dawnCenter: Qt.vector2d(root.dawnFrom.x, root.dawnFrom.y)
        property real dawnEdge: root.dawnEdge
        property real bandInside: Morph.dusk ? 0 : 1
        property color dawnLight: root.morphing ? Morph.to.light : "white"
        property vector2d resolution: Qt.vector2d(width, height)
        property real horizon: root.horizon
        property real relief: Config.terrainRelief * (root.planet.relief ?? 1)
        property real curve: root.radius
        property real planetAngle: root.angle
        property real orbit: root.space
        property color rimColor: root.tintA.skyLow
        property vector4d l0: root.bands(0)
        property vector4d l1: root.bands(4)
        property vector4d l2: root.bands(8)
        property vector4d l3: root.bands(12)
        property vector4d l4: root.bands(16)
        property vector4d l5: root.bands(20)
        property vector4d l6: root.bands(24)
        property real music: root.listening && Beat.dancing && Beat.shown.length ? 1 : 0
        property real lift: Theme.groundLift
        property real bars: Config.groundMusic === "bars" ? 1 : 0
        property real arrival: root.arrival
        property color arrivalLight: root.planet.light
        property real rough: root.planet.rough ?? 1
        property real flatRim: root.edge ? 1 : 0
        property real seed: root.formA.seed ?? 1.2
        property real farA: Morph.formOf(root.formA, "far")
        property real nearA: Morph.formOf(root.formA, "near")
        property real farB: Morph.formOf(root.formB, "far")
        property real nearB: Morph.formOf(root.formB, "near")
        property real seedB: root.formB.seed ?? 1.2
        property real reformAt: Morph.reformAt
        // The front runs out over the whole screen and a little more, slowing as it goes
        property real reformFront: root.reshaping ? (1 - (1 - Morph.front) * (1 - Morph.front)) * 2140 : -1
        property real sink: root.sinking ? Morph.sink : 0
        property real sunAt: root.planet.sun ?? 0.25
        property real cut: root.planet.cut ? 1 : 0
        property color next0: root.sweeping?.terrain[0] ?? layer0
        property color next1: root.sweeping?.terrain[1] ?? layer1
        property color next2: root.sweeping?.terrain[2] ?? layer2
        property color next3: root.sweeping?.terrain[3] ?? layer3
        property color nextRim: root.sweeping?.skyLow ?? rimColor
        property color sweepLight: root.sweeping?.light ?? "white"
        property vector2d sweepCenter: root.sweeping ? Qt.vector2d(root.tryOn.x, root.tryOn.y) : Qt.vector2d(0, 0)
        property real sweepReach: root.sweeping ? root.tryOn.reach : 0

        Behavior on music {
            NumberAnimation { duration: 1800; easing.type: Easing.InOutSine }
        }
        property real grain: Theme.grain

        layer.enabled: root.cached && music === 0 && arrival === 0 && !root.morphing
        fragmentShader: Qt.resolvedUrl("../../shaders/terrain.frag.qsb")
    }

    // And whatever stands in front of its hills, for a world that has any
    Scenery {
        anchors.fill: parent
        planet: root.planet
        front: true
        angle: root.angle
        horizon: root.horizon
        visible: root.space < 0.33 && root.groundOpacity > 0
        opacity: (1 - root.space * 3) * root.groundOpacity
    }
}
