pragma Singleton

import QtQuick
import Quickshell
import qs.config

// La Ceinture des ciels: choosing a picture is a short climb to where your air ends,
// with every picture hanging on a belt of small worlds around the planet.
// This holds what the belt is for and what's on it; the stage draws it.
Singleton {
    id: root

    // What the belt was opened for:
    //   role: "sky" (your sky), "world" (another world's sky), "newWorld", "lock", "photo"
    //   title, answer(path, from), from (where on screen it was asked from), planetId
    property var request: null
    readonly property bool open: request !== null
    readonly property string role: request?.role ?? ""
    readonly property var planet: request ? Planets.find(request.planetId) : Theme.planet

    // Everything on the belt, in order: the world's own sky first when it's a sky being
    // chosen, then the folder newest first, then a way out to another folder. Kept as it
    // was when the belt opened, and only rebuilt around where you are.
    property var items: []
    readonly property int count: items.length
    property real scroll: 0 // where the belt has turned to, in moons
    // A long flight only ever shows a screenful of moons going by: the ones that come on
    // during it are already the destination's neighbours. A moon is labelled as it comes
    // round onto the screen, with the item shift places past where it hangs.
    property int shift: 0
    property int zenith: wrap(Math.round(scroll) + shift) // the item at the top, as the belt shows it
    property real yours: 0 // how far your sky's moon hangs from the zenith, or 99 off the screen
    property int hovered: -1 // the item under the pointer
    // Where the zenith is along the whole folder, for the vernier: it follows the belt, and
    // a long flight carries it the true distance while the belt only turns a screenful
    property real vernierAt: 0
    readonly property bool turning: stepper.running || glide.running
    // The sky the world is wearing, which your own sky's moon stands for
    readonly property int wearing: {
        const sky = planet.sky ?? "";
        const found = items.findIndex(item => sky ? item.path === sky : item.special === "world");
        return Math.max(0, found);
    }
    property bool leaving: false
    // Your sky's moon grows its hills once it has taken over from the folding sky
    property real formed: 0

    function wrap(index) {
        return count ? (index % count + count) % count : 0;
    }

    // Where the moon d places from the zenith hangs on a belt of that radius round that
    // centre, and its shape there. The zenith is a loupe: θ + 3.5°·tanh(θ/7°), and near the
    // top a moon opens into a porthole shaped like the screen. Sizes grow with the planet.
    function placeOf(d, center, radius, unit, scale, screenAspect) {
        const phi = (11 * d + 3.5 * Math.tanh(11 * d / 7)) * Math.PI / 180;
        const t = Math.max(0, Math.min(1, Math.abs(d)));
        const z = 1 - t * t * (3 - 2 * t);
        const porthole = Theme.portholeWidth / 2 / screenAspect;
        return {
            x: center.x + radius * Math.sin(phi),
            y: center.y - radius * Math.cos(phi),
            halfHeight: (Theme.moonSize / 2 + (porthole - Theme.moonSize / 2) * z) * scale * unit,
            aspect: 1 + (screenAspect - 1) * z,
            exponent: 2 + 2.6 * z,
            z: z,
            phi: phi
        };
    }

    // How far an item is from a place on the belt, in moons, the short way round
    function along(index, at) {
        if (!count)
            return 0;
        const d = ((index - at) % count + count) % count;
        return d > count / 2 ? d - count : d;
    }

    function monthOf(mtime) {
        const date = new Date(Number(mtime) * 1000);
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
    }

    function build() {
        const list = [];
        if (role === "sky" || role === "world")
            list.push({ special: "world" });
        const sky = planet.sky ?? "";
        if (sky && !Pictures.pictures.some(picture => picture.path === sky))
            list.push({ path: sky, mtime: "", month: "" });
        for (const picture of Pictures.pictures)
            list.push({ path: picture.path, mtime: picture.mtime, month: monthOf(picture.mtime) });
        list.push({ special: "elsewhere" });
        return list;
    }

    function keyOf(item) {
        return item ? item.path ?? item.special : "";
    }

    // What a moon is called: its file's name, tidied, or what it stands for
    function nameOf(item) {
        if (!item)
            return "";
        if (item.special === "world")
            return planet.name;
        if (item.special === "elsewhere")
            return Lang.t("Autre dossier…");
        const name = item.path.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ").trim();
        return name.length > 34 ? name.slice(0, 33).trim() + "…" : name;
    }

    // « septembre 2026 · 38 sur 255 »
    function placeLine(index) {
        const item = items[index];
        const position = Lang.t("{0} sur {1}", index + 1, count);
        if (!item?.mtime)
            return position;
        const month = new Date(Number(item.mtime) * 1000).toLocaleDateString(Qt.locale(Lang.locale), "MMMM yyyy");
        return `${month} · ${position}`;
    }

    // Each moon's ink wobbles its own way
    function seedOf(item) {
        return item ? Qt.md5(keyOf(item)).charCodeAt(0) % 17 * 0.7 : 0;
    }

    // The colours a moon is drawn in: your world's own for the sky you wear, the world's
    // first colours for its painted sky, and each picture's for the others
    function paletteOf(item) {
        if (!item)
            return null;
        if (item === items[wearing] || item.special === "elsewhere")
            return planet;
        if (item.special === "world")
            return Planets.original(planet.id) ?? planet;
        return Palettes.of({ path: item.path, mtime: item.mtime })?.palette ?? null;
    }

    // The colour that stands for it: on the vernier, and while its moon is still a star
    function dominantOf(item) {
        if (item?.path && item.mtime)
            return Palettes.of({ path: item.path, mtime: item.mtime })?.dominant ?? String(planet.skyMid);
        return String(paletteOf(item)?.skyMid ?? planet.skyMid);
    }

    // A picture of the focused stage, saved to a file, to check a step without looking
    signal grabWanted(string path)

    // Turning the belt. Everything comes to rest on a moon.
    function holdTurn() {
        stepper.stop();
        glide.stop();
        vernierFlight.stop();
    }

    onScrollChanged: {
        if (!vernierFlight.running && count)
            vernierAt = ((scroll + shift) % count + count) % count;
    }

    // By hand: the fingers or the pointer move it 1:1
    function turnBy(moons) {
        holdTurn();
        scroll += moons;
    }

    // Let go: it carries on a little, at most 30 moons a second, and settles on a moon
    function fling(speed) {
        speed = Math.max(-30, Math.min(30, speed));
        glideTo(Math.round(scroll + speed * 0.28), 520, Easing.OutCubic);
    }

    // One moon per notch or key press, chained on a spring that overshoots a hair
    function step(moons) {
        const from = stepper.running ? stepper.to : Math.round(scroll);
        glide.stop();
        vernierFlight.stop();
        stepper.from = scroll;
        stepper.to = from + moons;
        stepper.restart();
    }

    // To an item anywhere in the folder, the short way round. Past a screenful, the belt
    // only visibly turns one screenful and the moons coming on are the destination's.
    function flyTo(index) {
        const moons = along(index, zenith);
        if (moons === 0) {
            glideTo(Math.round(scroll), 240, Easing.OutCubic);
            return;
        }
        const shown = Math.sign(moons) * Math.min(Math.abs(moons), 9);
        const duration = 520 * (0.75 + 0.25 * Math.min(Math.abs(shown), 5));
        shift += moons - shown;
        glideTo(Math.round(scroll) + shown, duration, Easing.InOutSine);
        vernierFlight.from = vernierAt;
        vernierFlight.to = wrap(index);
        vernierFlight.duration = duration;
        vernierFlight.restart();
    }

    function glideTo(to, duration, easing) {
        stepper.stop();
        glide.stop();
        glide.to = to;
        glide.duration = duration;
        glide.easing.type = easing;
        glide.start();
    }

    // Four fingers sideways turn the belt as they turn pages: fingers to the left bring on
    // the next moons, a page's worth of swipe is three moons, and it settles when they lift
    property real swipeSpeed: 0
    property real swipeTime: 0

    function swipe(step, value) {
        if (step === "start") {
            holdTurn();
            swipeSpeed = 0;
            swipeTime = Date.now();
        } else if (step === "move") {
            const moons = -Number(value) / Planet.swipeDistance * 3, now = Date.now();
            scroll += moons;
            swipeSpeed = swipeSpeed * 0.7 + moons / Math.max(8, now - swipeTime) * 1000 * 0.3;
            swipeTime = now;
        } else if (step === "end") {
            fling(value === "true" ? 0 : swipeSpeed); // cancelled, it just settles
        }
    }

    // Type the start of a name to go to it
    property string typed: ""

    function type(text) {
        typed = (typing.running ? typed : "") + text.toLowerCase();
        typing.restart();
        const found = items.findIndex(item => nameOf(item).toLowerCase().startsWith(typed));
        if (found >= 0)
            flyTo(found);
    }

    function ask(request) {
        if (open || Planet.phase !== Planet.Phase.Idle)
            return;
        root.request = request;
        items = build();
        holdTurn();
        shift = 0;
        scroll = wearing;
        zenith = wearing;
        vernierAt = wearing;
        yours = 0;
        formed = 0;
        leaving = false;
        Pictures.refresh();
        Planet.enterSkies();
    }

    function leave() {
        if (!Planet.inSkies)
            return;
        leaving = true;
        Planet.leaveSkies();
    }

    // The folder listed again while open: same place on the belt, whatever came in
    Connections {
        target: Pictures

        function onPicturesChanged() {
            if (!root.open)
                return;
            // Most of the time nothing came in or went: leave the belt as it is, turning or not
            const fresh = root.build();
            if (fresh.length === root.items.length && fresh.every((item, i) => root.keyOf(item) === root.keyOf(root.items[i])))
                return;
            const here = root.keyOf(root.items[root.zenith]);
            const offset = root.scroll - Math.round(root.scroll);
            root.holdTurn();
            root.items = fresh;
            const found = root.items.findIndex(item => root.keyOf(item) === here);
            root.shift = 0;
            root.scroll = (found < 0 ? root.wearing : found) + offset;
        }
    }

    Connections {
        target: Planet

        // Up at the edge, the folded sky hands over to its moon, whose hills rise
        function onAltitudeChanged() {
            if (Planet.inSkies && !root.leaving && Planet.altitude >= Planet.ceiling && root.formed === 0 && !rising.running)
                rising.start();
        }

        // Once the stage is back down, the request is over
        function onPhaseChanged() {
            if (Planet.phase === Planet.Phase.Idle) {
                root.request = null;
                root.leaving = false;
                rising.stop();
                root.formed = 0;
            }
        }
    }

    NumberAnimation {
        id: stepper

        target: root
        property: "scroll"
        duration: 360
        easing.type: Easing.OutBack
        easing.overshoot: 0.3
    }

    NumberAnimation {
        id: vernierFlight

        target: root
        property: "vernierAt"
        easing.type: Easing.InOutSine
    }

    NumberAnimation {
        id: glide

        target: root
        property: "scroll"
    }

    Timer {
        id: typing

        interval: 900
    }

    NumberAnimation {
        id: rising

        target: root
        property: "formed"
        from: 0
        to: 1
        duration: 280
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.expressive
    }
}
