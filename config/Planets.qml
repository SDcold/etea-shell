pragma Singleton

import QtQuick
import Quickshell

// The worlds you can live on. A theme is a planet, and a planet is just these few values,
// so adding one means adding one entry here. Each one takes after a planet of our own
// system, and its style follows from it.
Singleton {
    // Every world as you've left it: what it came with, then whatever you changed on it
    readonly property var all: builtIn.concat(Config.customPlanets).map(planet => Object.assign({}, planet, Config.planetTweaks[planet.id] ?? {}))

    readonly property var builtIn: [
        {
            id: "aster",
            name: "Aster",
            line: Lang.t("Le soir qui ne finit pas."),
            skyTop: "#2b3a55",
            skyMid: "#c9744b",
            skyLow: "#f2b872",
            terrain: ["#a8553c", "#7a3a33", "#4f2630", "#2c1622"],
            light: "#ffe2a8",
            sun: 0.75, // on the right: the giant keeps its shading
            // Saturn: its ring is the bar, its moons turn in the dials
            style: { barStyle: "band", pageStyle: "constellation", widgetStyle: "celestial", lockScene: "hand" }
        },
        {
            id: "nere",
            name: "Néré",
            line: Lang.t("Un océan sous la brume."),
            skyTop: "#0e2a3a",
            skyMid: "#2a7f86",
            skyLow: "#b9e5d3",
            terrain: ["#3f9089", "#2a6a70", "#1a4a55", "#0e2c3a"],
            light: "#c8fff0",
            // Neptune, the sea god: open water, and the stars to steer by
            style: { barStyle: "sky", pageStyle: "constellation", widgetStyle: "sky", lockScene: "skyward" }
        },
        {
            id: "ocre",
            name: "Ocre",
            line: Lang.t("La poussière et la lumière."),
            skyTop: "#3a4a43",
            skyMid: "#b59a3c",
            skyLow: "#ecdca0",
            terrain: ["#8a7a35", "#5f5a2e", "#3f4227", "#22281b"],
            light: "#fff0b0",
            // Mars: scattered outposts, mission numbers, habitat portholes
            style: { barStyle: "islands", pageStyle: "numbers", widgetStyle: "celestial", lockScene: "hand" }
        },
        {
            id: "vesper",
            name: "Vesper",
            line: Lang.t("La nuit a déjà commencé."),
            skyTop: "#15102e",
            skyMid: "#6b3f9e",
            skyLow: "#e59ac0",
            terrain: ["#7a3f8a", "#54306e", "#382352", "#1c1430"],
            light: "#ffc8e6",
            // Venus, the evening star: the first light once night has come
            style: { barStyle: "sky", pageStyle: "constellation", widgetStyle: "sky", lockScene: "skyward" }
        }
    ]

    function find(id) {
        return all.find(planet => planet.id === id) ?? all[0];
    }

    // Which scenery stands in a world: its own for the built-in ones, none for the others
    // unless picked. An empty name means none.
    function sceneOf(planet) {
        return planet.scenery ?? ({ aster: "Aster" })[planet.id] ?? "";
    }

    // Whether a world shows its hills: as you set it, or else yes under its own sky, and
    // under a picture of yours only if you want hills over pictures
    function groundOf(planet) {
        if (planet?.ground !== undefined)
            return planet.ground;
        const sky = planet?.sky ?? "";
        return !sky || sky === original(planet.id)?.sky || Config.hillsOnPictures;
    }

    // How the world was before you touched it
    function original(id) {
        return builtIn.concat(Config.customPlanets).find(planet => planet.id === id) ?? null;
    }

    function tweak(id, changes) {
        const tweaks = Object.assign({}, Config.planetTweaks);
        tweaks[id] = Object.assign({}, tweaks[id] ?? {}, changes);
        Config.planetTweaks = tweaks;
    }

    // Back to how it came, all of it or only some of what you changed
    function untweak(id, keys) {
        const tweaks = Object.assign({}, Config.planetTweaks);
        if (keys && tweaks[id]) {
            tweaks[id] = Object.assign({}, tweaks[id]);
            for (const key of keys)
                delete tweaks[id][key];
        }
        if (!keys || Object.keys(tweaks[id] ?? {}).length === 0)
            delete tweaks[id];
        Config.planetTweaks = tweaks;
    }
}
