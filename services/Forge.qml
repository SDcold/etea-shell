pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

// Turns any image into a world: it reads the picture's colours and works out a sky,
// a terrain and a light that belong together, whatever the picture looks like.
Singleton {
    id: root

    property string image: ""
    property var draft: null // the planet being made, until you keep it or let it go
    property bool keepSky: true // the picture itself becomes the sky, not only its colours
    property bool keepGround: true
    // Pictures kept as skies are copied here, so moving the original doesn't empty the sky
    readonly property string skies: `${Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share"}/etea/skies`

    function clamp(value, low, high) {
        return Math.max(low, Math.min(high, value));
    }

    function read(path) {
        draft = null;
        image = path;
    }

    // Colours in OKLCH, where lightness and colourfulness are as the eye sees them
    function oklchOf(color) {
        const linear = c => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        const r = linear(color.r), g = linear(color.g), b = linear(color.b);
        const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
        const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
        const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
        const L = 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s;
        const A = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s;
        const B = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s;
        return { l: L, c: Math.hypot(A, B), h: (Math.atan2(B, A) * 180 / Math.PI + 360) % 360 };
    }

    // Back to a colour, its chroma lowered until it fits on a screen
    function oklch(lightness, chroma, hue) {
        const toRgb = c => {
            const a = c * Math.cos(hue * Math.PI / 180), b = c * Math.sin(hue * Math.PI / 180);
            const l = Math.pow(lightness + 0.3963377774 * a + 0.2158037573 * b, 3);
            const m = Math.pow(lightness - 0.1055613458 * a - 0.0638541728 * b, 3);
            const s = Math.pow(lightness - 0.0894841775 * a - 1.291485548 * b, 3);
            return [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s];
        };
        const fits = rgb => rgb.every(v => v >= -0.0005 && v <= 1.0005);
        let low = 0, high = chroma, rgb = toRgb(chroma);
        if (!fits(rgb)) {
            for (let i = 0; i < 18; i++) {
                const mid = (low + high) / 2;
                if (fits(toRgb(mid)))
                    low = mid;
                else
                    high = mid;
            }
            rgb = toRgb(low);
        }
        const gamma = v => {
            v = clamp(v, 0, 1);
            return v <= 0.0031308 ? 12.92 * v : 1.055 * Math.pow(v, 1 / 2.4) - 0.055;
        };
        return String(Qt.rgba(gamma(rgb[0]), gamma(rgb[1]), gamma(rgb[2]), 1));
    }

    // A sky, a terrain and a light from a picture's colours, or nothing if it has too few.
    // After Material You, as end4's colorgen uses it: the source colour is the one that
    // scores best on how colourful it is and how much of the picture its hue covers, greys
    // left out; a picture with little colour gets the neutral scheme, the others a tonal
    // spot. Everything else is that one hue at chosen lightnesses, so it all belongs together.
    function paletteOf(found) {
        if (found.length < 2)
            return null;
        // Each colour stands for about as many pixels: the quantizer splits them evenly
        const colors = found.map(color => oklchOf(color));
        const share = 1 / colors.length;
        const near = (a, b) => Math.abs(((a - b) % 360 + 540) % 360 - 180) <= 15;

        let source = null, best = -Infinity;
        for (const color of colors) {
            if (color.c < 0.015)
                continue; // a grey: its hue means nothing
            const covered = colors.filter(other => other.c >= 0.015 && near(other.h, color.h)).length * share;
            const score = covered * 70 + (color.c - 0.135) * (color.c < 0.135 ? 35 : 105);
            if (score > best) {
                best = score;
                source = color;
            }
        }
        const hue = source?.h ?? 0;
        const sourceChroma = source?.c ?? 0;
        // Neutral when the picture as a whole has little colour (end4 reads that as a
        // colourfulness under 40), or its source does (under 20 of Material's chroma); a
        // tonal spot otherwise. Never more colour than the picture has.
        const colourful = colors.reduce((sum, color) => sum + color.c, 0) / colors.length;
        const neutral = colourful < 0.04 || sourceChroma < 0.055;
        const accent = neutral ? Math.min(sourceChroma, 0.034) : 0.1;
        const quiet = neutral ? Math.min(sourceChroma, 0.012) : 0.025;

        return {
            skyTop: oklch(0.24, quiet, hue),
            skyMid: oklch(0.62, accent, hue),
            skyLow: oklch(0.9, quiet * 1.5, hue),
            // The hills, back to front: lighter and a little quieter far off, darker close by
            terrain: [[0.64, 0.8], [0.52, 1], [0.4, 0.9], [0.27, 0.7]].map(([lightness, amount]) => oklch(lightness, accent * amount, hue)),
            light: oklch(0.96, neutral ? quiet : 0.03, hue)
        };
    }

    function build() {
        const palette = paletteOf(quantizer.colors);
        if (!palette)
            return;
        const name = image.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ").slice(0, 24);
        draft = Object.assign({
            id: `forge-${Date.now()}`,
            name: name.charAt(0).toUpperCase() + name.slice(1),
            line: Lang.t("Née d'une image.")
        }, palette);
    }

    // A wallpaper picked from the bar becomes the sky of the world you're on, and that world's
    // colours are drawn from it again: no new planet. The colours come from Palettes, read
    // once from a thumbnail, and the picture is loaded at screen size before anything
    // changes, so the star opens onto it whole.
    property var wearing: null // { path, from, palette, loaded }

    function wear(path, from) {
        const picture = Pictures.pictures.find(p => p.path === path) ?? { path: path, mtime: "" };
        wearing = { path: path, picture: picture, from: from, palette: Palettes.of(picture)?.palette ?? null, loaded: false };
        preload.source = "";
        preload.source = Pictures.url(path);
    }

    function wearWhenReady() {
        const next = wearing;
        if (!next || !next.palette || !next.loaded)
            return;
        wearing = null;
        const id = Config.theme;
        Planet.changeLook(() => Planets.tweak(id, Object.assign({}, next.palette, { sky: next.path, scenery: "" })), next.from);
    }

    // The world's own sky and colours again
    function unwear(from) {
        const id = Config.theme;
        Planet.changeLook(() => Planets.untweak(id, ["sky", "skyTop", "skyMid", "skyLow", "terrain", "light", "scenery"]), from);
    }

    // Its colours, if they weren't known yet when it was picked
    Connections {
        target: Palettes

        function onLearnt(path) {
            if (!root.wearing || root.wearing.path !== path)
                return;
            root.wearing.palette = Palettes.of(root.wearing.picture)?.palette ?? null;
            root.wearWhenReady();
        }
    }

    // Decoded once here at the size the sky asks for, the sky then finds it ready
    Image {
        id: preload

        readonly property var screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

        visible: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(screen?.width ?? 0, screen?.height ?? 0)
        onStatusChanged: {
            if (root.wearing && (status === Image.Ready || status === Image.Error)) {
                root.wearing.loaded = true;
                root.wearWhenReady();
            }
        }
    }

    // Keeping it makes it your home straight away
    function keep(name) {
        if (!draft)
            return;
        const planet = Object.assign({}, draft, { name: name || draft.name });
        if (!keepGround)
            planet.ground = false;
        draft = null;
        if (keepSky) {
            const sky = `${skies}/${planet.id}.${image.split(".").pop().toLowerCase()}`;
            copier.planet = Object.assign(planet, { sky: sky });
            copier.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && cp -f "$1" "$2"', "sh", image, sky];
            copier.running = true;
        } else {
            settle(planet);
        }
        image = "";
    }

    function settle(planet) {
        Config.customPlanets = Config.customPlanets.concat([planet]);
        Planet.changeWorld(planet.id);
    }

    function forget(id) {
        const planet = Config.customPlanets.find(planet => planet.id === id);
        if (planet?.sky?.startsWith(skies + "/"))
            Quickshell.execDetached(["rm", "-f", planet.sky]);
        Config.customPlanets = Config.customPlanets.filter(planet => planet.id !== id);
        Planets.untweak(id);
        if (Config.theme === id)
            Config.theme = "aster";
    }

    // The picture is in its place before the sky asks for it. If it couldn't be copied,
    // the planet still comes with the colours it drew from it.
    Process {
        id: copier

        property var planet: null

        onExited: code => {
            if (code !== 0)
                delete planet.sky;
            root.settle(planet);
        }
    }

    function chooseImage(item) {
        Pictures.pick(Lang.t("Une image pour ta planète"), path => root.read(path), { role: "newWorld", item: item });
    }

    // A new sky for a world that already exists: copied like the others, then worn
    function chooseSky(id, item) {
        Pictures.pick(Lang.t("Un ciel pour {0}", Planets.find(id).name), path => root.adoptSky(id, path), { role: "world", planetId: id, item: item });
    }

    function adoptSky(id, path) {
        const sky = `${skies}/${id}-${Date.now()}.${path.split(".").pop().toLowerCase()}`;
        skyCopier.planetId = id;
        skyCopier.sky = sky;
        skyCopier.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && cp -f "$1" "$2"', "sh", path, sky];
        skyCopier.running = true;
    }

    // Back to the painted sky. A copy only this world was using goes with it.
    function dropSky(id) {
        const sky = Planets.find(id).sky ?? "";
        if (sky.startsWith(skies + "/") && sky !== Planets.original(id)?.sky)
            Quickshell.execDetached(["rm", "-f", sky]);
        Planets.tweak(id, { sky: "" });
    }

    Process {
        id: skyCopier

        property string planetId: ""
        property string sky: ""

        onExited: code => {
            if (code === 0)
                Planets.tweak(planetId, { sky: sky });
        }
    }

    ColorQuantizer {
        id: quantizer

        source: root.image ? `file://${root.image}` : ""
        depth: 4
        rescaleSize: 96
        onColorsChanged: root.build()
    }

    IpcHandler {
        target: "forge"

        function preview(path: string): void {
            root.read(path);
        }

        function palette(): string {
            return JSON.stringify(root.draft);
        }
    }
}
