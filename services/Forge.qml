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
            line: "Née d'une image.",
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
        Config.customPlanets = Config.customPlanets.concat([planet]);
        Config.theme = planet.id;
        draft = null;
        image = "";
    }

    function forget(id) {
        Config.customPlanets = Config.customPlanets.filter(planet => planet.id !== id);
        if (Config.theme === id)
            Config.theme = "aster";
    }

    function chooseImage() {
        picker.running = true;
    }

    ColorQuantizer {
        id: quantizer

        source: root.image ? `file://${root.image}` : ""
        depth: 4
        rescaleSize: 96
        onColorsChanged: root.build()
    }

    Process {
        id: picker

        command: ["sh", "-c", 'if command -v kdialog >/dev/null; then kdialog --title "Une image pour ta planète" --getopenfilename "$HOME" "*.png *.jpg *.jpeg *.webp"; else zenity --file-selection --title "Une image pour ta planète"; fi']
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.read(text.trim());
            }
        }
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
