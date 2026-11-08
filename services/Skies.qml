pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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
    // Trying skies on: the air and the planet up here wear `shown`, your world's colours
    // at first. Once the belt rests on a moon, its picture's colours sweep out of it as a
    // star; that sweep is `next`, `sweep` from 0 to 1, out of the moon `sweepFrom` places
    // from the zenith. Your page is never touched.
    property var shown: null
    property var next: null
    property real sweep: 0
    property real sweepFrom: 0
    // Looking at a sky full size, or landing one: the lens grows out of its moon, `chosenAt`
    // places from the zenith, back into the whole sky behind your page
    property bool looking: false
    property bool landing: false
    property int chosen: -1
    property real chosenAt: 0
    property bool committed: false
    property bool rehearsal: false // lands it all the way without wearing it, to check how it goes
    // Every sky is worn from a copy the size of the screen, made by vips: what the lens
    // shows is then exactly what the background will load, and moving the original
    // can't empty the sky. { path: copy } for the copies made so far.
    property var copies: ({})
    readonly property var screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    readonly property size screenSize: Qt.size(screen?.width ?? 1920, screen?.height ?? 1080)
    readonly property var largest: Quickshell.screens.reduce((best, s) => s.width * s.height > best.width * best.height ? s : best, Quickshell.screens[0])
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

    function copyName(item) {
        return `${Forge.skies}/worn-${Qt.md5(item.path + item.mtime)}-${largest.width}x${largest.height}.jpg`;
    }

    // The copy a picture is shown and worn from, once made; asked for after a moment at rest
    function copyOf(item) {
        return item?.path ? copies[item.path] ?? "" : "";
    }

    function wantCopy(item) {
        if (!item?.path || copies[item.path] || copier.wanted?.path === item.path)
            return;
        copier.wanted = item;
        copier.next();
    }

    // What the lens shows of an item: its copy, or the world's painted sky
    function lensOf(index) {
        const item = items[index];
        return {
            path: copyOf(item) || (item?.path ?? ""),
            thumb: item?.path ? Pictures.thumb(Pictures.pictures.find(p => p.path === item.path) ?? item, 0) : "",
            palette: paletteOf(item),
            painted: !item?.path,
            seed: seedOf(item)
        };
    }

    // Space held: the camera sinks along the landing path, so the sky at the top grows behind
    // your page; let go and everything climbs back
    function look(on) {
        if (!Planet.inSkies || landing || leaving)
            return;
        const item = items[zenith];
        if (on && (!item || item.special === "elsewhere"))
            return;
        if (on) {
            holdTurn();
            chosen = zenith;
            chosenAt = 0;
            wantCopy(item);
            looking = true;
            Planet.lookTo(Planet.ceiling * 0.25);
        } else if (looking) {
            Planet.lookTo(Planet.ceiling);
        }
    }

    // Choosing: down commits, as everywhere in ETEA. The chosen sky's colours sweep out of its
    // moon, it grows back into your sky as you land, and is worn behind the stage on the way.
    function choose(index, at) {
        if (!Planet.inSkies || landing || leaving)
            return;
        index = index ?? zenith;
        const item = items[index];
        if (!item)
            return;
        if (item.special === "elsewhere") {
            browse();
            return;
        }
        if (index === wearing) {
            leave();
            return;
        }
        if (role !== "sky") {
            // Asked for a path: it goes back to whoever asked. A world's own painted sky,
            // asked for that world, takes its picture away.
            const answer = request?.answer, id = planet.id;
            leave();
            if (item.special === "world")
                Forge.dropSky(id);
            else if (answer && item.path)
                answer(item.path, request?.from);
            return;
        }
        holdTurn();
        resting.stop();
        chosen = index;
        chosenAt = at ?? 0;
        landing = true;
        committed = false;
        sweepOut(paletteOf(item), chosenAt, Theme.skyLand * 0.4);
        wantCopy(item);
        if (!item.path || copyOf(item) && preload.status === Image.Ready)
            land();
        else
            copyWait.restart();
    }

    function land() {
        copyWait.stop();
        Planet.leaveSkies(Theme.skyLand);
    }

    // Three quarters of the way down, behind the stage, the world puts it on
    function commit() {
        committed = true;
        if (rehearsal) {
            console.info(`ETEA skies: rehearsed landing ${nameOf(items[chosen])}, copy ${copyOf(items[chosen]) ? "ready" : "missing"}`);
            Planet.hold = true;
            preload.source = Pictures.url(copyOf(items[chosen]) || items[chosen].path || "");
            revealWait.waited = 0;
            revealWait.restart();
            return;
        }
        const item = items[chosen];
        const id = planet.id;
        if (item.special === "world") {
            Planets.untweak(id, ["sky", "skyTop", "skyMid", "skyLow", "terrain", "light", "scenery"]);
            return;
        }
        const palette = paletteOf(item);
        const sky = copyOf(item) || item.path;
        Planet.hold = true;
        preload.source = Pictures.url(sky);
        revealWait.waited = 0;
        revealWait.restart();
        Planets.tweak(id, Object.assign({}, palette ?? {}, { sky: sky, scenery: "" }));
    }

    // Somewhere else: the system's own picker, once the stage is out of its way
    function browse() {
        const answer = role === "sky" ? (path => Forge.wear(path)) : request?.answer;
        browsing.title = request?.title ?? "";
        leave();
        browsing.answer = answer;
        browsing.restart();
    }

    // The colours sweep out of a moon over the last ones, which are worn from then on
    function sweepOut(palette, from, duration) {
        const wearing = next ?? shown ?? planet;
        if (!palette || palette === wearing)
            return;
        if (sweeping.running)
            shown = next;
        next = palette;
        sweepFrom = from;
        sweeping.duration = duration;
        sweeping.restart();
    }

    function tryOn() {
        if (!Planet.inSkies || leaving || turning)
            return;
        sweepOut(paletteOf(items[zenith]), 0, 600);
    }

    onTurningChanged: {
        if (!turning)
            resting.restart();
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
        sweeping.stop();
        shown = null;
        next = null;
        sweep = 0;
        Pictures.refresh();
        Planet.enterSkies();
    }

    function leave() {
        if (!Planet.inSkies)
            return;
        leaving = true;
        resting.stop();
        // Your own colours sweep back from your sky's moon, or from the zenith
        sweepOut(planet, Math.abs(yours) < 5 ? yours : 0, 320);
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
            if (root.landing && !root.committed && Planet.altitude <= Planet.ceiling * 0.25)
                root.commit();
            if (root.looking && !Planet.inSkies)
                root.looking = false;
            if (root.looking && Planet.altitude >= Planet.ceiling)
                root.looking = false;
            if (Planet.inSkies && !root.leaving && Planet.altitude >= Planet.ceiling && root.formed === 0 && !rising.running) {
                rising.start();
                resting.restart();
            }
        }

        // Once the stage is back down, the request is over
        function onPhaseChanged() {
            if (Planet.phase === Planet.Phase.Idle) {
                root.request = null;
                root.leaving = false;
                rising.stop();
                root.formed = 0;
                resting.stop();
                root.looking = false;
                root.landing = false;
                root.rehearsal = false;
                root.chosen = -1;
                root.tidy();
                sweeping.stop();
                root.shown = null;
                root.next = null;
                root.sweep = 0;
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

    // At rest a moment, the zenith's colours are tried on, and a little later its copy made
    Timer {
        id: resting

        interval: 140
        onTriggered: {
            root.tryOn();
            copyLater.restart();
        }
    }

    Timer {
        id: copyLater

        interval: 160
        onTriggered: {
            if (Planet.inSkies && !root.turning)
                root.wantCopy(root.items[root.zenith]);
        }
    }

    // Copies are made one at a time, the latest wish only
    Process {
        id: copier

        property var wanted: null
        property var making: null

        function next() {
            if (running || !wanted)
                return;
            making = wanted;
            wanted = null;
            const out = root.copyName(making);
            const largest = root.largest;
            command = ["sh", "-c", `
                [ -s "$2" ] && { echo "$2"; exit 0; }
                mkdir -p "$(dirname "$2")"
                w=$(vipsheader -f width "$1") && h=$(vipsheader -f height "$1") || exit 1
                # Covering the screen, never larger than the picture itself
                if [ $((w * $4)) -gt $((h * $3)) ]; then
                    vips thumbnail "$1" "$2.part.jpg[Q=95,subsample-mode=off,strip]" 100000 --height "$4" --size down
                else
                    vips thumbnail "$1" "$2.part.jpg[Q=95,subsample-mode=off,strip]" "$3" --height 100000 --size down
                fi && mv "$2.part.jpg" "$2" && echo "$2"`, "sh", making.path, out, String(largest.width), String(largest.height)];
            running = true;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const made = text.trim();
                const item = copier.making;
                if (made && item) {
                    root.copies[item.path] = made;
                    root.copies = root.copies;
                    preload.source = Pictures.url(made);
                }
            }
        }
        onExited: {
            making = null;
            next();
        }
    }

    // The copy decoded once at the size the background asks for, so it finds it ready
    Image {
        id: preload

        visible: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: root.screenSize
        onStatusChanged: {
            if (status === Image.Ready && copyWait.running)
                root.land();
        }
    }

    // Chosen too early, it waits for its copy, a little and no more
    Timer {
        id: copyWait

        interval: 1500
        onTriggered: root.land()
    }

    // Worn, the stage steps aside once the sky is decoded and has had time to be drawn,
    // or after a second and a half whatever happens
    Timer {
        id: revealWait

        property int waited: 0

        interval: 160
        repeat: true
        onTriggered: {
            waited += interval;
            if (preload.status !== Image.Loading || waited >= 1500) {
                stop();
                Planet.hold = false;
            }
        }
    }

    Timer {
        id: browsing

        property var answer: null
        property string title: ""

        interval: Theme.skyRise + 200
        onTriggered: Pictures.browseThen(answer, title)
    }

    // Copies no world is wearing any more are deleted once the belt has closed
    function tidy() {
        const worn = Planets.all.map(p => p.sky ?? "").filter(sky => sky.includes("/worn-"));
        copies = ({});
        Quickshell.execDetached(["sh", "-c", 'cd "$1" 2>/dev/null || exit 0; shift; for f in worn-*.jpg; do [ -e "$f" ] || continue; keep=0; for w in "$@"; do [ "$w" = "$PWD/$f" ] && keep=1; done; [ $keep = 1 ] || rm -f "$f"; done', "sh", Forge.skies].concat(worn));
    }

    NumberAnimation {
        id: sweeping

        target: root
        property: "sweep"
        from: 0
        to: 1
        easing.type: Easing.InOutSine
        onFinished: {
            root.shown = root.next;
            root.next = null;
            root.sweep = 0;
        }
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
