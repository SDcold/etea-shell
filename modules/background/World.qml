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

    // Four sound levels at a time, the way the shader wants them
    function bands(first) {
        const levels = Beat.shown;
        return Qt.vector4d(levels[first] ?? 0, levels[first + 1] ?? 0, levels[first + 2] ?? 0, levels[first + 3] ?? 0);
    }

    ShaderEffect {
        anchors.fill: parent

        // Painted, or while your picture is still on its way
        visible: root.skyImage === "" || pictureSource.status !== Image.Ready

        property color colorTop: root.planet.skyTop
        property color colorMid: root.planet.skyMid
        property color colorLow: root.planet.skyLow
        property vector2d resolution: Qt.vector2d(width, height)
        property real grain: Theme.grain
        property real space: root.space

        layer.enabled: root.cached
        fragmentShader: Qt.resolvedUrl("../../shaders/sky.frag.qsb")
    }

    // Loaded just big enough to cover the screen, the shader does the cropping
    Image {
        id: pictureSource

        visible: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        source: root.skyImage ? "file://" + root.skyImage : ""
    }

    ShaderEffect {
        anchors.fill: parent

        visible: root.skyImage !== "" && pictureSource.status === Image.Ready

        property var picture: pictureSource
        property vector2d pictureSize: Qt.vector2d(pictureSource.implicitWidth, pictureSource.implicitHeight)
        property vector2d resolution: Qt.vector2d(width, height)
        property real grain: Theme.grain
        property real space: root.space

        layer.enabled: root.cached
        fragmentShader: Qt.resolvedUrl("../../shaders/skyimage.frag.qsb")
    }

    // The world's own sky: its moons, its rings, its clouds. Gone once we've left the air.
    Scenery {
        anchors.fill: parent
        planet: root.planet
        angle: root.angle
        horizon: root.horizon
        visible: root.space < 0.33
        opacity: 1 - root.space * 3
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
        anchors.fill: parent

        // Without hills the ground only shows once it has become a planet, up in orbit
        opacity: root.groundOpacity * (root.ground ? 1 : Math.min(1, root.space * 3))
        visible: opacity > 0

        // planetAngle is what will spin the planet between pages
        property color layer0: root.planet.terrain[0]
        property color layer1: root.planet.terrain[1]
        property color layer2: root.planet.terrain[2]
        property color layer3: root.planet.terrain[3]
        property vector2d resolution: Qt.vector2d(width, height)
        property real horizon: root.horizon
        property real relief: Config.terrainRelief * (root.planet.relief ?? 1)
        property real curve: root.radius
        property real planetAngle: root.angle
        property real orbit: root.space
        property color rimColor: root.planet.skyLow
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

        Behavior on music {
            NumberAnimation { duration: 1800; easing.type: Easing.InOutSine }
        }
        property real grain: Theme.grain

        layer.enabled: root.cached && music === 0 && arrival === 0
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
