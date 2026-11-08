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
    property real grow: 1 // the moons grow and shrink with the planet, 1 at the edge
    property bool showYours: true // false while your own sky is still folding into its moon

    readonly property real radius: Theme.skyBelt * planetRadius
    readonly property real screenAspect: width / Math.max(1, height)
    readonly property int pool: 13

    // Slot j hangs at j + 13·round((scroll − j)/13): always the thirteen nearest places.
    // It's labelled as it moves to a new place, which only happens off the screen.
    function placeFor(slot) {
        return slot + pool * Math.round((Skies.scroll - slot) / pool);
    }

    // The belt says which item is at the top, and where your own sky's moon hangs
    function report() {
        const top = Math.round(Skies.scroll);
        let yours = 99;
        for (let slot = 0; slot < moons.count; slot++) {
            const moon = moons.itemAt(slot);
            if (!moon)
                continue;
            if (moon.place === top)
                Skies.zenith = moon.item;
            if (moon.item === Skies.wearing && Math.abs(moon.offset) < Math.abs(yours))
                yours = moon.offset;
        }
        Skies.yours = yours;
    }

    Connections {
        target: Skies

        function onScrollChanged() {
            for (let slot = 0; slot < moons.count; slot++)
                moons.itemAt(slot)?.relabel(false);
            root.report();
        }

        function onItemsChanged() {
            for (let slot = 0; slot < moons.count; slot++)
                moons.itemAt(slot)?.relabel(true);
            root.report();
        }
    }

    // The caption over the zenith, rewritten only once the belt is still: the name opens
    // from the middle, with where it sits in the folder and what Enter would do
    readonly property bool still: Math.abs(Skies.scroll - Math.round(Skies.scroll)) < 0.001
    readonly property real showing: {
        const t = Math.max(0, Math.min(1, (Planet.altitude - 0.47) / 0.13));
        return t * t * (3 - 2 * t);
    }
    property int captioned: -1
    readonly property real captionTop: center.y - radius - Theme.portholeWidth / 2 / screenAspect * grow * unit

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

    // The vernier: the whole folder as a band of colour along your horizon, one tick per
    // picture in its own colour, the months written along it where they fit. Its ticks
    // grow out of the limb as you arrive.
    readonly property real spread: 52 * Math.PI / 180
    readonly property real ticks: {
        const v = Planet.altitude / Planet.ceiling;
        return Math.max(0, Math.min(1, (v - 0.6) / 0.4));
    }
    readonly property var months: {
        const list = [], n = Skies.count;
        let last = "", lastAt = -1e9;
        for (let i = 0; i < n; i++) {
            const month = Skies.items[i].month;
            if (!month || month === last)
                continue;
            last = month;
            const angle = -spread + 2 * spread * i / Math.max(1, n - 1);
            // Room for its name along the limb, in units of a 1600 wide screen
            if ((angle + spread) * planetRadius / unit - lastAt < 70)
                continue;
            lastAt = (angle + spread) * planetRadius / unit;
            list.push({ angle: angle, name: new Date(Number(Skies.items[i].mtime) * 1000).toLocaleDateString(Qt.locale(Lang.locale), "MMMM") });
        }
        return list;
    }

    // Each item's colour, a pixel each, for the vernier to read
    Canvas {
        id: strip

        width: Math.max(1, Skies.count)
        height: 1
        visible: false
        onPaint: {
            const g = getContext("2d");
            for (let i = 0; i < Skies.count; i++) {
                g.fillStyle = Skies.dominantOf(Skies.items[i]);
                g.fillRect(i, 0, 1, 1);
            }
        }

        Connections {
            target: Palettes

            function onVersionChanged() {
                strip.requestPaint();
            }
        }

        Connections {
            target: Skies

            function onItemsChanged() {
                strip.requestPaint();
            }
        }
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.ticks > 0

        property color light: Skies.planet.light
        property vector2d resolution: Qt.vector2d(width, height)
        property vector2d center: Qt.vector2d(root.center.x, root.center.y)
        property real radius: root.planetRadius
        property real count: Skies.count
        property real spread: root.spread
        property real grow: root.ticks
        property real unit: root.unit
        property real at: Skies.vernierAt
        property real yours: Skies.wearing
        property var strip: strip

        fragmentShader: Qt.resolvedUrl("../../shaders/vernier.frag.qsb")
    }

    Repeater {
        model: root.months

        Text {
            required property var modelData
            readonly property real reach: root.planetRadius + 27 * root.unit

            x: root.center.x + Math.sin(modelData.angle) * reach - width / 2
            y: root.center.y - Math.cos(modelData.angle) * reach - height / 2
            rotation: modelData.angle * 180 / Math.PI
            text: modelData.name
            color: Qt.alpha(Theme.skyInk, 0.5 * root.ticks)
            font.family: Theme.font
            font.pixelSize: Math.round(11 * root.unit)
            visible: root.ticks > 0
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
        property real moonHalf: Theme.moonSize / 2 * root.grow * root.unit
        property real portholeHalf: Theme.portholeWidth / 2 / root.screenAspect * root.grow * root.unit
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
            id: moon

            required property int index
            property int place: index // where on the belt it hangs, in moons, unwrapped
            property int labelled: 0 // the shift it was labelled with
            readonly property int item: Skies.wrap(place + labelled)
            // A short folder must not show an item twice
            readonly property bool counted: place - Math.round(Skies.scroll) >= -Math.floor((Skies.count - 1) / 2) && place - Math.round(Skies.scroll) <= Math.ceil((Skies.count - 1) / 2)
            readonly property bool yours: item === Skies.wearing

            function relabel(always) {
                const want = root.placeFor(index);
                if (want === place && !always)
                    return;
                place = want;
                labelled = Skies.shift;
            }

            Component.onCompleted: {
                relabel(true);
                root.report();
            }

            entry: counted ? Skies.items[item] ?? null : null
            center: root.center
            radius: root.radius
            grow: root.grow
            unit: root.unit
            screenAspect: root.screenAspect
            offset: place - Skies.scroll
            hovered: Skies.hovered === item && Math.abs(offset) < 6
            inked: yours ? Skies.formed : 1
            // Off the screen, still behind the folding sky, or growing into one
            visible: !((Skies.looking || Skies.landing) && item === Skies.chosen && Math.abs(offset - Skies.chosenAt) < 0.5) && entry !== null && Math.abs(offset) < 6.6 && (!yours || root.showYours) && y < root.height && y + height > 0 && x + width > 0 && x < root.width
        }
    }
}
