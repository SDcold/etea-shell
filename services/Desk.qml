pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
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
        { type: "media", label: Lang.t("Lecteur de musique"), icon: "music" },
        { type: "weather", label: Lang.t("Météo"), icon: "cloud-sun" },
        { type: "calendar", label: Lang.t("Calendrier et lune"), icon: "calendar" },
        { type: "tasks", label: Lang.t("Tâches"), icon: "checklist" },
        { type: "photo", label: Lang.t("Cadre photo"), icon: "image" },
        { type: "lyrics", label: Lang.t("Paroles"), icon: "lyrics" }
    ]

    // Where each one stands until you move it, and which of its points stands there:
    // 0 is its left or top edge, 1 the other one. They keep to the sides, the middle
    // belongs to the clock.
    readonly property var places: Theme.widgetStyle === "sky" ? {
        clock: { x: 0.5, y: 0.5, ax: 0.5, ay: 0.5 },
        system: { x: 0.044, y: 0.085, ax: 0, ay: 0 },
        media: { x: 0.956, y: 0.085, ax: 1, ay: 0 },
        weather: { x: 0.956, y: 0.33, ax: 1, ay: 0 },
        calendar: { x: 0.044, y: 0.36, ax: 0, ay: 0 },
        tasks: { x: 0.956, y: 0.58, ax: 1, ay: 0 },
        photo: { x: 0.3, y: 0.62, ax: 0.5, ay: 0.5 },
        lyrics: { x: 0.5, y: 0.15, ax: 0.5, ay: 0.5 }
    } : {
        clock: { x: 0.5, y: 0.34, ax: 0.5, ay: 0.5 },
        system: { x: 0.14, y: 0.3, ax: 0.5, ay: 0.5 },
        media: { x: 0.84, y: 0.3, ax: 0.5, ay: 0.5 },
        weather: { x: 0.84, y: 0.6, ax: 0.5, ay: 0.5 },
        calendar: { x: 0.64, y: 0.68, ax: 0.5, ay: 0.5 },
        tasks: { x: 0.14, y: 0.62, ax: 0.5, ay: 0.5 },
        photo: { x: 0.32, y: 0.64, ax: 0.5, ay: 0.5 },
        lyrics: { x: 0.5, y: 0.12, ax: 0.5, ay: 0.5 }
    }

    // Only changes when a widget comes or goes, so moving one doesn't rebuild the others
    property var shown: []

    property string hovered: "" // the widget under the pointer, for Super + wheel
    property bool carrying: false // a widget is being dragged right now
    // When Hyprland last said Super + left button went down over a widget. A moment, not a
    // state: let go of Super before the button and Hyprland never says it's over.
    property real grabbedAt: 0
    property real lastGesture: 0 // when a Super gesture last landed on a widget
    readonly property bool frozen: Config.widgetsFrozen // they stay where they are, at their size

    // Hyprland's Super + drag moves windows, and swallows the click even over the empty
    // desktop. So while the pointer rests on a widget, that bind steps aside for one of
    // ours that lets the click through and tells us Super is down: the desktop never has
    // the keyboard, so the click itself arrives without it. It comes back as soon as the
    // pointer leaves, and only if there was such a bind to begin with. Hyprland remembers
    // it was swapped, so a reload or a crash of the shell can't leave it missing.
    property bool windowDrag: false
    property bool lifted: false
    readonly property bool liftWanted: windowDrag && !frozen && (hovered !== "" || carrying)

    readonly property string putBack: 'if ETEA_LIFTED then hl.unbind("SUPER + mouse:272") hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Window: Move" }) end ETEA_LIFTED = false'

    onLiftWantedChanged: lift()

    function lift() {
        if (swap.running || lifted === liftWanted)
            return;
        lifted = liftWanted;
        swap.command = ["hyprctl", "eval", lifted ? 'hl.unbind("SUPER + mouse:272") hl.bind("SUPER + mouse:272", hl.dsp.global("etea:deskGrab"), { non_consuming = true }) ETEA_LIFTED = true' : root.putBack];
        swap.running = true;
    }

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

    // Each style keeps its own place and size for every widget: sky widgets hang from the
    // screen's edges, celestial cards stand on their middle, so one spot can't suit both
    readonly property string style: Theme.widgetStyle === "sky" ? "sky" : "celestial"

    // What this style remembers of a widget. Before styles kept their own, a widget moved by
    // hand was moved under the sky style, and the file's first coordinates were celestial.
    function own(type) {
        const saved = entry(type);
        if (saved.at?.[style])
            return saved.at[style];
        if (style === "sky")
            return saved.placed ? { x: saved.x, y: saved.y, size: saved.size } : { size: saved.size };
        return !saved.placed && saved.x !== undefined ? { x: saved.x, y: saved.y } : {};
    }

    // Where it stands now: its own spot once moved, the style's default until then
    function place(type) {
        const mine = own(type), base = places[type] ?? { x: 0.5, y: 0.5, ax: 0.5, ay: 0.5 };
        return mine.x !== undefined ? { x: mine.x, y: mine.y, ax: base.ax, ay: base.ay } : base;
    }

    function size(type) {
        return own(type).size ?? 1;
    }

    // Keeps a place or a size for this style only
    function keep(type, changes) {
        const saved = entry(type);
        update(type, { at: Object.assign({}, saved.at ?? {}, { [style]: Object.assign({}, own(type), changes) }) });
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
        keep(type, { x: Math.max(0, Math.min(1, x)), y: Math.max(0, Math.min(1, y)) });
    }

    function resize(type, value) {
        keep(type, { size: Math.round(Math.max(0.5, Math.min(1.6, value)) * 100) / 100 });
    }

    function grow(type, steps) {
        if (frozen)
            return;
        lastGesture = Date.now();
        resize(type, size(type) + steps * 0.05);
    }

    // Only the click Hyprland just announced counts, the next plain click must stay plain
    function takeGrab() {
        const fresh = Date.now() - grabbedAt < 250;
        grabbedAt = 0;
        return fresh;
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

    GlobalShortcut {
        appid: "etea"
        name: "deskGrab"
        onPressed: root.grabbedAt = Date.now()
    }

    // The pointer can come and go faster than hyprctl answers, so catch up once it's done
    Process {
        id: swap

        onExited: root.lift()
    }

    // Anything a previous run left lifted comes back before we look
    Process {
        running: true
        command: ["hyprctl", "eval", root.putBack]
        onExited: binds.running = true
    }

    // Is there a Super + left button bind to step aside?
    Process {
        id: binds

        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windowDrag = JSON.parse(text).some(bind => bind.modmask === 64 && bind.key === "mouse:272");
                } catch (error) {
                    root.windowDrag = false;
                }
            }
        }
    }

    // A reload brings Hyprland's binds back as they were written
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                root.lifted = false;
                binds.running = true;
                root.lift();
            }
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
