import QtQuick
import QtQuick.Effects
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
    property bool ground: Planets.groundOf(planet)
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
    // Set by the stage while a sky lands: how far the hills have sunk on the way down
    property real landSink: 0
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

    // Four sound levels at a time, the way the shader wants them, or the slower copy's. Only
    // read while the ground dances: otherwise every level another listener hears would redraw
    // the music strip.
    function bands(first, late) {
        if (!(music.dance > 0))
            return Qt.vector4d(0, 0, 0, 0);
        const levels = late ? Beat.trail : Beat.shown;
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
        property real veil: Config.orbitBackdrop === "space" ? 0 : 1

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

    // Seen from orbit, your picture stays behind the stars, blurred and dimmed: a small copy,
    // cropped to the screen and blurred once, which the sky shader stretches back up
    Item {
        id: blurredSky

        width: 320
        height: Math.max(1, Math.round(320 * root.height / Math.max(1, root.width)))
        visible: false
        layer.enabled: root.skyImage !== ""

        Image {
            id: smallPicture

            anchors.fill: parent
            visible: false
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(parent.width * 2, parent.height * 2)
            source: root.skyImage && Config.orbitBackdrop !== "space" ? Pictures.url(root.skyImage) : ""
        }

        MultiEffect {
            anchors.fill: parent
            source: smallPicture
            blurEnabled: true
            blur: 1
            blurMax: 48
            autoPaddingEnabled: false
        }
    }

    ShaderEffect {
        anchors.fill: parent

        visible: !root.edge && root.skyImage !== "" && pictureSource.status === Image.Ready

        property var picture: pictureSource
        property var blurred: blurredSky
        property vector2d pictureSize: Qt.vector2d(pictureSource.implicitWidth, pictureSource.implicitHeight)
        property vector2d resolution: Qt.vector2d(width, height)
        property real grain: Theme.grain
        property real space: root.space
        property real veil: Config.orbitBackdrop === "space" ? 0 : 1

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

    // The music on the ground, in a strip of its own at the bottom: only that strip is drawn
    // again each frame it dances, the hills in front of it stay a still picture
    ShaderEffect {
        id: music

        // Fades in as the music starts and out as it stops, behind the hills
        property real dance: root.listening && Beat.dancing && Beat.shown.length ? 1 : 0
        readonly property real hillsShown: root.ground ? 1 : Math.min(1, root.space * 3)
        readonly property real climb: Theme.groundLift * (hillsShown > 0.5 ? 1.5 : 1.1) // how high, in units
        readonly property real maxAmp: Math.min(root.radius * 0.024, 34) * Config.terrainRelief * (root.planet.relief ?? 1) * (1 - root.space)
        // From just above the highest it can climb, down to the bottom of the screen
        // Stars float a little higher than bars stand
        // and the constellations they let go drift higher still
        readonly property real tallest: ({ stars: climb * 1.3 + 40 + ghostRise, astrolabe: climb * 2 + 6, greatstar: climb * 2.6, aurora: climb * 2.1 })[Config.groundMusic] ?? climb
        readonly property real stripTop: hillsShown > 0.5 ? root.height * root.horizon - (maxAmp + tallest + 12) * root.unit : root.height - (tallest + 12) * root.unit

        Behavior on dance {
            NumberAnimation { duration: 1800; easing.type: Easing.InOutSine }
        }

        x: 0
        y: Math.max(0, Math.floor(stripTop))
        width: root.width
        height: root.height - y
        opacity: dance * (1 - root.space) * root.groundOpacity
        visible: opacity > 0 && Config.groundMusic !== "off"

        property vector4d l0: root.bands(0)
        property vector4d l1: root.bands(4)
        property vector4d l2: root.bands(8)
        property vector4d l3: root.bands(12)
        property vector4d l4: root.bands(16)
        property vector4d l5: root.bands(20)
        property vector4d l6: root.bands(24)
        // The same, slower, for what lags behind; the ink around the shapes; the strikes
        property vector4d t0: root.bands(0, true)
        property vector4d t1: root.bands(4, true)
        property vector4d t2: root.bands(8, true)
        property vector4d t3: root.bands(12, true)
        property vector4d t4: root.bands(16, true)
        property vector4d t5: root.bands(20, true)
        property vector4d t6: root.bands(24, true)
        property color outline: Qt.darker(root.tintA.skyTop, 1.8)
        property vector4d pulse: dance > 0 ? Qt.vector4d(Beat.pulse[0], Beat.pulse[1], Beat.pulse[2], Beat.calm) : Qt.vector4d(0, 0, 0, 0)
        property color ink: ({ accent: Desk.accent, ink: Desk.ink, world: root.planet.light })[Config.musicColor] ?? root.tintA.skyLow
        property color light: ({ accent: Desk.accentLight, ink: Desk.ink })[Config.musicColor] ?? "#fff8eb"
        property vector2d world: Qt.vector2d(root.width, root.height)
        property vector2d origin: Qt.vector2d(x, y)
        property vector2d size: Qt.vector2d(width, height)
        property real horizon: root.horizon
        property real curve: root.radius
        property real relief: Config.terrainRelief * (root.planet.relief ?? 1)
        property real orbit: root.space
        property real planetAngle: root.angle
        property real seed: root.formA.seed ?? 1.2
        property real farA: Morph.formOf(root.formA, "far")
        property real rough: root.planet.rough ?? 1
        property real hills: hillsShown
        property real style: ({ lines: 0, bars: 1, stars: 2, astrolabe: 3, greatstar: 4, aurora: 5 })[Config.groundMusic] ?? 0
        property real reach: climb
        property real density: Config.musicDensity
        // Its own clock, only running while it shows, for the stars to breathe and sparkle
        property real time: 0

        NumberAnimation on time {
            running: music.visible
            from: 0
            to: 3600
            duration: 3600000
            loops: Animation.Infinite
        }

        // What the music strikes, among the stars: a star born on the horizon, a spark sent
        // along the constellation, and the constellation itself let go to drift into the sky.
        // Each lives in a few slots, stamped with the clock above; a strike finding every
        // slot still busy is let pass.
        readonly property real ghostRise: climb * 0.9
        readonly property real ghostLife: 2.6 // as the shader has it
        readonly property real sparkLife: 1.1
        property vector4d birth0: Qt.vector4d(0, -100, 0, 1)
        property vector4d birth1: Qt.vector4d(0, -100, 0, 1)
        property vector4d birth2: Qt.vector4d(0, -100, 0, 1)
        property vector4d birth3: Qt.vector4d(0, -100, 0, 1)
        property vector4d birth4: Qt.vector4d(0, -100, 0, 1)
        property vector4d birth5: Qt.vector4d(0, -100, 0, 1)
        property vector4d birth6: Qt.vector4d(0, -100, 0, 1)
        property vector4d birth7: Qt.vector4d(0, -100, 0, 1)
        property vector2d spark0: Qt.vector2d(-100, 0)
        property vector2d spark1: Qt.vector2d(-100, 0)
        property vector2d spark2: Qt.vector2d(-100, 0)
        property var ghostTimes: [-100, -100, -100, -100, -100, -100, -100, -100]
        property var ghostRows: [[], [], [], [], [], [], [], []]
        property vector4d ghostAt0: Qt.vector4d(ghostTimes[0], ghostTimes[1], ghostTimes[2], ghostTimes[3])
        property vector4d ghostAt1: Qt.vector4d(ghostTimes[4], ghostTimes[5], ghostTimes[6], ghostTimes[7])
        property var ghosts: ghostRowsPicture
        property real lastSpark: -100
        property real lastGhost: -100

        function strike(band, strength) {
            const now = time;
            for (let i = 0; i < 8; i++) {
                if (now - music["birth" + i].y > music["birth" + i].w) {
                    music["birth" + i] = Qt.vector4d(band, now, strength, 1.1 - 0.6 * band / 25);
                    break;
                }
            }
            // A strike in the lows also sends a spark and lets the constellation go
            if (band >= 6 || strength < 0.25)
                return;
            if (now - lastSpark > 0.3) {
                for (let i = 0; i < 3; i++) {
                    if (now - music["spark" + i].x > sparkLife) {
                        music["spark" + i] = Qt.vector2d(now, strength);
                        lastSpark = now;
                        break;
                    }
                }
            }
            if (now - lastGhost > 0.45)
                letGo();
        }

        // What each band of the constellation hears right now, as the shader reckons it
        function letGo() {
            const now = time;
            const slot = ghostTimes.findIndex(at => now - at > ghostLife);
            if (slot < 0)
                return;
            const levels = Beat.shown;
            const row = [];
            for (let c = 0; c < 26; c++)
                row.push(1 - Math.exp(-(levels[c] ?? 0) * 1.9 * (0.6 + 0.7 * c / 25)));
            const rows = ghostRows.slice();
            rows[slot] = row;
            ghostRows = rows;
            const times = ghostTimes.slice();
            times[slot] = now;
            ghostTimes = times;
            lastGhost = now;
        }

        // The clock starts again from 0 each time the music shows: forget what it stamped
        function forget() {
            for (let i = 0; i < 8; i++)
                music["birth" + i] = Qt.vector4d(0, -100, 0, 1);
            for (let i = 0; i < 3; i++)
                music["spark" + i] = Qt.vector2d(-100, 0);
            ghostTimes = [-100, -100, -100, -100, -100, -100, -100, -100];
            lastSpark = -100;
            lastGhost = -100;
        }

        onVisibleChanged: forget()

        Connections {
            target: Beat
            enabled: music.visible && music.style === 2

            function onStruck(band, strength) {
                music.strike(band, strength);
            }
        }

        // In a quiet stretch with no strike in the lows, the constellation still lets go now and then
        Timer {
            interval: 1500
            repeat: true
            running: music.visible && music.style === 2
            onTriggered: {
                if (music.time - music.lastGhost > 1.4 && Math.max(0, ...Beat.shown) > 0.15)
                    music.letGo();
            }
        }

        fragmentShader: Qt.resolvedUrl("../../shaders/music.frag.qsb")
    }

    // The constellations the music let go, one row of 26 bands each, as a tiny picture for its
    // shader, kept just off the screen
    Item {
        id: ghostRowsPicture

        x: -64
        width: 26
        height: 8
        layer.enabled: true
        layer.smooth: false

        Repeater {
            model: 26 * 8

            Rectangle {
                required property int index

                x: index % 26
                y: Math.floor(index / 26)
                width: 1
                height: 1
                color: Qt.rgba(music.ghostRows[y]?.[x] ?? 0, 0, 0, 1)
            }
        }
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
        property real sink: Math.max(root.sinking ? Morph.sink : 0, root.landSink)
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

        property real grain: Theme.grain

        layer.enabled: root.cached && arrival === 0 && !root.morphing
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
