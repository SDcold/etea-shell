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
    property real scroll: 0 // where the belt has turned to, in moons; the zenith's is round(scroll)
    readonly property int zenith: wrap(Math.round(scroll))
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

    function ask(request) {
        if (open || Planet.phase !== Planet.Phase.Idle)
            return;
        root.request = request;
        items = build();
        scroll = wearing;
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
            const here = root.keyOf(root.items[root.zenith]);
            const offset = root.scroll - Math.round(root.scroll);
            root.items = root.build();
            const found = root.items.findIndex(item => root.keyOf(item) === here);
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
