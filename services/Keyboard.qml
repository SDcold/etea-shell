pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

// The keyboard's languages. Settings picks them, the bar shows the one in use and a
// click moves to the next. Until you pick some here, Hyprland's own config decides.
Singleton {
    id: root

    property var layouts: [] // the codes in use, like ["us", "fr"]
    property int current: 0
    property string currentName: "" // "English (US)", as Hyprland names it
    property var known: [] // every layout xkb knows: { code, name }
    readonly property string code: layouts[current] ?? ""

    signal switched()

    function next() {
        switcher.exec(["hyprctl", "switchxkblayout", "all", "next"]);
    }

    function select(index) {
        switcher.exec(["hyprctl", "switchxkblayout", "all", String(index)]);
    }

    function choose(list) {
        Config.keyboardLayouts = list;
        apply();
    }

    function apply() {
        if (!Config.keyboardLayouts.length)
            return;
        applier.exec(["hyprctl", "eval", `hl.config({ input = { kb_layout = "${Config.keyboardLayouts.join(",")}" } })`]);
    }

    function nameOf(code) {
        return known.find(layout => layout.code === code)?.name ?? code.toUpperCase();
    }

    Process {
        id: switcher
    }

    Process {
        id: applier

        onExited: reader.running = true
    }

    // What the main keyboard is set to right now
    Process {
        id: reader

        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(text).keyboards;
                    const main = keyboards.find(keyboard => keyboard.main) ?? keyboards[0];
                    root.layouts = main.layout.split(",").map(code => code.trim()).filter(code => code);
                    root.current = main.active_layout_index ?? 0;
                    root.currentName = main.active_keymap ?? "";
                } catch (error) {}
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activelayout") {
                const before = root.currentName;
                root.currentName = event.data.split(",").slice(1).join(",");
                reader.running = true;
                if (root.currentName !== before)
                    root.switched();
            } else if (event.name === "configreloaded") {
                // A reload brings Hyprland's own layouts back, ours go on top again
                root.apply();
                reader.running = true;
            }
        }
    }

    // The names behind the codes, from xkb's own list
    FileView {
        path: "/usr/share/X11/xkb/rules/evdev.lst"
        onLoaded: {
            const lines = text().split("\n"), found = [];
            let inside = false;
            for (const line of lines) {
                if (line.startsWith("!")) {
                    inside = line.startsWith("! layout");
                    continue;
                }
                const match = inside && line.match(/^\s+(\S+)\s+(.+)$/);
                if (match)
                    found.push({ code: match[1], name: match[2].trim() });
            }
            root.known = found.sort((a, b) => a.name.localeCompare(b.name));
        }
    }

    Component.onCompleted: {
        apply();
        reader.running = true;
    }
}
