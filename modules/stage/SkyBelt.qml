import QtQuick
import qs.config
import qs.services

// The belt of skies: every picture hangs on a great circle round the planet, at the edge
// of the air, 11° apart. The zenith is a loupe, a pure function of where the belt has
// turned to: a moon θ from the top is drawn at θ + 3.5°·tanh(θ/7°), and near the top it
// opens into a porthole showing the whole picture. Thirteen moons are enough for any
// screen; each is handed the next item along as it leaves the screen.
Item {
    id: root

    property point center // the planet's centre, in pixels
    property real planetRadius // in pixels
    property real unit: width / 1600
    property real scale: 1 // the moons grow and shrink with the planet, 1 at the edge
    property bool showYours: true // false while your own sky is still folding into its moon

    readonly property real radius: Theme.skyBelt * planetRadius
    readonly property real screenAspect: width / Math.max(1, height)
    readonly property int pool: 13

    // Slot j shows the item j + 13·round((scroll − j)/13): always the thirteen nearest
    function itemFor(slot) {
        const index = slot + root.pool * Math.round((Skies.scroll - slot) / root.pool);
        // A short folder must not show an item twice
        const offset = index - Math.round(Skies.scroll);
        if (offset < -Math.floor((Skies.count - 1) / 2) || offset > Math.ceil((Skies.count - 1) / 2))
            return -1;
        return index;
    }

    // The caption over the zenith, rewritten only once the belt is still: the name opens
    // from the middle, with where it sits in the folder and what Enter would do
    readonly property bool still: Math.abs(Skies.scroll - Math.round(Skies.scroll)) < 0.001
    readonly property real showing: {
        const t = Math.max(0, Math.min(1, (Planet.altitude - 0.47) / 0.13));
        return t * t * (3 - 2 * t);
    }
    property int captioned: -1
    readonly property real captionTop: center.y - radius - Theme.portholeWidth / 2 / screenAspect * scale * unit

    function caption() {
        if (!still || captioned === Skies.zenith)
            return;
        captioned = Skies.zenith;
        reveal.restart();
    }

    onStillChanged: caption()
    Component.onCompleted: caption()

    Connections {
        target: Skies

        function onZenithChanged() {
            root.caption();
        }
    }

    // The ink line, broken around each moon
    ShaderEffect {
        id: line

        anchors.fill: parent

        property color light: Skies.planet.light
        property vector2d resolution: Qt.vector2d(width, height)
        property vector2d center: Qt.vector2d(root.center.x, root.center.y)
        property real radius: root.radius
        property real seed: 4
        // The shader finds the moons itself, from where the belt has turned to
        property real turned: Skies.scroll - Math.round(Skies.scroll)
        property real before: Math.floor((Skies.count - 1) / 2)
        property real after: Math.ceil((Skies.count - 1) / 2)
        property real moonHalf: Theme.moonSize / 2 * root.scale * root.unit
        property real portholeHalf: Theme.portholeWidth / 2 / root.screenAspect * root.scale * root.unit
        property real screenAspect: root.screenAspect
        property real room: 10 * root.unit

        visible: root.center.y - root.radius < root.height
        fragmentShader: Qt.resolvedUrl("../../shaders/belt.frag.qsb")
    }

    Item {
        id: words

        property real reveal: 1
        readonly property var entry: Skies.items[root.captioned] ?? null

        anchors.fill: parent
        visible: root.showing > 0 && root.captioned >= 0
        opacity: root.showing * (root.still ? 1 : 0.35)

        Behavior on opacity {
            NumberAnimation { duration: 160 }
        }

        NumberAnimation {
            id: reveal

            target: words
            property: "reveal"
            from: 0
            to: 1
            duration: 280
            easing.type: Easing.OutCubic
        }

        // The name, opening from the middle
        Item {
            x: (root.width - width) / 2
            y: root.captionTop - 54 * root.unit - name.baselineOffset
            width: (name.implicitWidth + 4) * words.reveal
            height: name.implicitHeight
            clip: true

            Text {
                id: name

                x: (parent.width - implicitWidth) / 2
                text: Skies.nameOf(words.entry)
                color: Qt.alpha(Theme.skyInk, 0.94)
                font.family: Theme.font
                font.pixelSize: Math.round(28 * root.unit)
                font.weight: Font.Light
            }
        }

        Text {
            x: (root.width - implicitWidth) / 2
            y: root.captionTop - 34 * root.unit - baselineOffset
            text: root.captioned >= 0 ? Skies.placeLine(root.captioned) : ""
            color: Qt.alpha(Theme.skyInk, 0.45)
            font.family: Theme.font
            font.pixelSize: Math.round(13 * root.unit)
        }

        Text {
            readonly property bool yours: root.captioned === Skies.wearing

            x: (root.width - implicitWidth) / 2
            y: root.captionTop - 16 * root.unit - baselineOffset
            visible: words.entry?.special !== "elsewhere"
            text: yours ? Lang.t("Ton ciel") : Lang.t("Entrée pour en faire ton ciel · Espace pour regarder")
            color: yours ? Qt.alpha(Skies.planet.light, 0.95) : Qt.alpha(Theme.skyInk, 0.55)
            font.family: Theme.font
            font.pixelSize: Math.round(13 * root.unit)
        }

        // What the belt was opened for, top left
        Text {
            x: 28 * root.unit
            y: 34 * root.unit - baselineOffset
            text: Skies.request?.title ?? ""
            color: Qt.alpha(Theme.skyInk, 0.55)
            font.family: Theme.font
            font.pixelSize: Math.round(13 * root.unit)
        }
    }

    Repeater {
        id: moons

        model: root.pool

        SkyMoon {
            required property int index
            readonly property int at: (Skies.count, root.itemFor(index))

            readonly property bool yours: Skies.wrap(at) === Skies.wearing

            entry: at < 0 ? null : Skies.items[Skies.wrap(at)] ?? null
            center: root.center
            radius: root.radius
            scale: root.scale
            unit: root.unit
            screenAspect: root.screenAspect
            offset: at - Skies.scroll
            rise: yours ? Skies.formed : 1
            inked: yours ? Skies.formed : 1
            // Off the screen, or still behind the folding sky
            visible: entry !== null && Math.abs(offset) < 6.6 && (!yours || root.showYours) && y < root.height && y + height > 0 && x + width > 0 && x < root.width
        }
    }
}
