pragma Singleton

import QtQuick
import Quickshell

// The worlds you can live on. A theme is a planet, and a planet is just these few values,
// so adding one means adding one entry here.
Singleton {
    readonly property var all: [
        {
            id: "aster",
            name: "Aster",
            line: "Le soir qui ne finit pas.",
            skyTop: "#2b3a55",
            skyMid: "#c9744b",
            skyLow: "#f2b872",
            terrain: ["#a8553c", "#7a3a33", "#4f2630", "#2c1622"],
            light: "#ffe2a8"
        },
        {
            id: "nere",
            name: "Néré",
            line: "Un océan sous la brume.",
            skyTop: "#0e2a3a",
            skyMid: "#2a7f86",
            skyLow: "#b9e5d3",
            terrain: ["#3f9089", "#2a6a70", "#1a4a55", "#0e2c3a"],
            light: "#c8fff0"
        },
        {
            id: "ocre",
            name: "Ocre",
            line: "La poussière et la lumière.",
            skyTop: "#3a4a43",
            skyMid: "#b59a3c",
            skyLow: "#ecdca0",
            terrain: ["#8a7a35", "#5f5a2e", "#3f4227", "#22281b"],
            light: "#fff0b0"
        },
        {
            id: "vesper",
            name: "Vesper",
            line: "La nuit a déjà commencé.",
            skyTop: "#15102e",
            skyMid: "#6b3f9e",
            skyLow: "#e59ac0",
            terrain: ["#7a3f8a", "#54306e", "#382352", "#1c1430"],
            light: "#ffc8e6"
        }
    ]

    function find(id) {
        return all.find(planet => planet.id === id) ?? all[0];
    }
}
