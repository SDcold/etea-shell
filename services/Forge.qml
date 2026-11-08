pragma Singleton

import QtQuick
import Quickshell
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

    function hex(hue, saturation, value) {
        return String(Qt.hsva(Math.max(0, hue), saturation, value, 1));
    }

    function read(path) {
        draft = null;
        image = path;
    }

    function build() {
        const colors = quantizer.colors.map(color => ({
            hue: color.hsvHue,
            saturation: color.hsvSaturation,
            value: color.hsvValue,
            light: color.r * 0.3 + color.g * 0.59 + color.b * 0.11,
            vivid: color.hsvSaturation * color.hsvValue
        }));
        if (colors.length < 2)
            return;

        const byLight = colors.slice().sort((a, b) => a.light - b.light);
        const dark = byLight[Math.floor(byLight.length * 0.12)];
        const bright = byLight[Math.floor(byLight.length * 0.88)];
        const vivid = colors.reduce((best, color) => color.vivid > best.vivid ? color : best);
        const body = clamp(vivid.saturation, 0.35, 0.7);
        const name = image.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ").slice(0, 24);

        draft = {
            id: `forge-${Date.now()}`,
            name: name.charAt(0).toUpperCase() + name.slice(1),
            line: Lang.t("Née d'une image."),
            skyTop: hex(dark.hue, clamp(dark.saturation, 0.3, 0.75), clamp(dark.value, 0.14, 0.34)),
            skyMid: hex(vivid.hue, clamp(vivid.saturation, 0.45, 0.8), clamp(vivid.value, 0.55, 0.85)),
            skyLow: hex(bright.hue, clamp(bright.saturation, 0.2, 0.55), clamp(bright.value, 0.85, 0.97)),
            terrain: [0.58, 0.42, 0.28, 0.15].map(value => hex(vivid.hue, body, value)),
            light: hex(bright.hue, 0.22, 1)
        };
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

    function chooseImage() {
        Pictures.pick(Lang.t("Une image pour ta planète"), path => root.read(path));
    }

    // A new sky for a world that already exists: copied like the others, then worn
    function chooseSky(id) {
        Pictures.pick(Lang.t("Un ciel pour {0}", Planets.find(id).name), path => root.adoptSky(id, path));
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
