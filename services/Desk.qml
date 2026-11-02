pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The widgets on the desktop: which ones are out, where they stand, how big they are.
// Everything is saved in Config.widgets, one entry per kind of widget.
Singleton {
    id: root

    // Every kind of widget there is
    readonly property var catalog: [
        { type: "clock", label: Lang.t("Horloge"), icon: "timer" },
        { type: "system", label: Lang.t("Instruments du système"), icon: "cpu" },
        { type: "media", label: Lang.t("Lecteur de musique"), icon: "music" }
    ]

    // Where each one stands until you move it, and which of its points stands there:
    // 0 is its left or top edge, 1 the other one
    readonly property var places: Config.widgetStyle === "sky" ? {
        clock: { x: 0.5, y: 0.5, ax: 0.5, ay: 0.5 },
        system: { x: 0.044, y: 0.085, ax: 0, ay: 0 },
        media: { x: 0.956, y: 0.085, ax: 1, ay: 0 }
    } : {
        clock: { x: 0.5, y: 0.34, ax: 0.5, ay: 0.5 },
        system: { x: 0.14, y: 0.3, ax: 0.5, ay: 0.5 },
        media: { x: 0.84, y: 0.3, ax: 0.5, ay: 0.5 }
    }

    // Only changes when a widget comes or goes, so moving one doesn't rebuild the others
    property var shown: []

    property string hovered: "" // the widget under the pointer, for Super + wheel
    property real lastGesture: 0 // when a Super gesture last landed on a widget

    // The card of options, opened with a right click
    property string menuFor: "" // a widget, "add" for the empty sky, or nothing
    property point menuAt: Qt.point(0, 0)
    property var menuScreen: null

    function label(type) {
        return catalog.find(entry => entry.type === type)?.label ?? type;
    }

    function entry(type) {
        return Config.widgets.find(widget => widget.type === type) ?? { type: type, shown: false };
    }

    // Where it stands now: its own spot once moved, the style's default until then
    function place(type) {
        const saved = entry(type), base = places[type] ?? { x: 0.5, y: 0.5, ax: 0.5, ay: 0.5 };
        if (saved.placed)
            return { x: saved.x, y: saved.y, ax: base.ax, ay: base.ay };
        // The celestial style always read x and y from the file
        if (Config.widgetStyle !== "sky" && saved.x !== undefined)
            return { x: saved.x, y: saved.y, ax: base.ax, ay: base.ay };
        return base;
    }

    function size(type) {
        return entry(type).size ?? 1;
    }

    function update(type, changes) {
        const list = Config.widgets.slice();
        const at = list.findIndex(widget => widget.type === type);
        if (at < 0)
            list.push(Object.assign({ type: type }, changes));
        else
            list[at] = Object.assign({}, list[at], changes);
        Config.widgets = list;
    }

    function add(type) {
        update(type, { shown: true });
    }

    function remove(type) {
        update(type, { shown: false });
    }

    function move(type, x, y) {
        update(type, { x: Math.max(0, Math.min(1, x)), y: Math.max(0, Math.min(1, y)), placed: true });
    }

    function grow(type, steps) {
        lastGesture = Date.now();
        update(type, { size: Math.round(Math.max(0.5, Math.min(1.6, size(type) + steps * 0.05)) * 100) / 100 });
    }

    function openMenu(type, at, screen) {
        menuAt = at;
        menuScreen = screen;
        menuFor = type;
    }

    function refresh() {
        const next = Config.widgets.filter(widget => widget.shown !== false && catalog.some(entry => entry.type === widget.type)).map(widget => widget.type);
        if (next.join() !== shown.join())
            shown = next;
    }

    Connections {
        target: Config

        function onWidgetsChanged() {
            root.refresh();
        }
    }

    // qs ipc call desk state, or add, remove and grow from a script
    IpcHandler {
        target: "desk"

        function state(): string {
            return root.shown.map(type => {
                const at = root.place(type);
                return `${type} at ${at.x.toFixed(3)},${at.y.toFixed(3)} size ${root.size(type)}`;
            }).join("\n");
        }

        function add(type: string): void {
            root.add(type);
        }

        function remove(type: string): void {
            root.remove(type);
        }

        function grow(type: string, steps: int): void {
            root.grow(type, steps);
        }
    }

    Component.onCompleted: refresh()
}
