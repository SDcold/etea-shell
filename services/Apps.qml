pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

// Your sky of apps: what's installed, what you open most, and how to find anything.
Singleton {
    id: root

    property bool open: false
    property var uses: ({})

    readonly property var everything: DesktopEntries.applications.values.filter(app => !app.noDisplay)

    // How the sky is divided into constellations
    readonly property var families: [
        { name: Lang.t("Création"), categories: ["Graphics", "AudioVideo", "Audio", "Video"] },
        { name: "Code", categories: ["Development"] },
        { name: Lang.t("Internet"), categories: ["Network", "WebBrowser", "Chat", "Email"] },
        { name: Lang.t("Le reste"), categories: [] }
    ]

    function usesOf(app) {
        return uses[app.id] ?? 0;
    }

    function byUse(a, b) {
        return usesOf(b) - usesOf(a) || a.name.localeCompare(b.name);
    }

    function familyOf(app) {
        const found = families.findIndex(family => family.categories.some(category => app.categories.includes(category)));
        return found < 0 ? families.length - 1 : found;
    }

    function appEntry(app) {
        return { kind: "app", label: app.name, icon: Quickshell.iconPath(app.icon, "application-x-executable"), app: app };
    }

    // Nothing typed: the whole map, your favourites at the heart of each constellation
    function map() {
        return families.map((family, index) => ({
            name: family.name,
            stars: everything.filter(app => familyOf(app) === index).sort(byUse).slice(0, 5).map(appEntry)
        }));
    }

    // Starting with what you typed beats a word starting with it, which beats anywhere at all
    function score(app, text) {
        const name = app.name.toLowerCase();
        if (name.startsWith(text))
            return 40;
        if (name.split(/\s+/).some(word => word.startsWith(text)))
            return 30;
        if (name.includes(text))
            return 20;
        const extra = `${app.genericName} ${app.comment} ${app.keywords.join(" ")}`.toLowerCase();
        return extra.includes(text) ? 10 : 0;
    }

    // A sum, if what you typed is one. Only digits and operators ever reach the evaluation.
    function sum(text) {
        const cleaned = text.replace(/,/g, ".").replace(/\^/g, "**").trim();
        if (!/^[\d\s+\-*/().%]+$/.test(cleaned) || !/[+\-*/%]/.test(cleaned))
            return null;
        try {
            const value = new Function(`return (${cleaned})`)();
            return Number.isFinite(value) ? Math.round(value * 1e6) / 1e6 : null;
        } catch (error) {
            return null;
        }
    }

    // Typing: sums, commands, open windows and apps, whatever fits best first
    function search(text) {
        const typed = text.trim(), wanted = typed.toLowerCase(), found = [];
        const asset = name => "file://" + Quickshell.shellPath(`assets/icons/${name}.svg`);

        if (typed.startsWith(">") && typed.length > 1)
            return [{ kind: "command", label: Lang.t("Lancer {0}", typed.slice(1).trim()), icon: asset("play"), command: typed.slice(1).trim() }];

        const result = sum(typed);
        if (result !== null)
            found.push({ kind: "sum", label: `= ${result}`, icon: asset("search"), value: String(result) });

        for (const window of Hyprland.toplevels.values) {
            const title = window.title ?? "", kind = window.lastIpcObject?.class ?? "";
            if (title.toLowerCase().includes(wanted) || kind.toLowerCase().includes(wanted)) {
                const app = DesktopEntries.heuristicLookup(kind);
                found.push({ kind: "window", label: Lang.t("Aller à {0}", app?.name ?? title), icon: Quickshell.iconPath(app?.icon ?? "", "application-x-executable"), window: window });
            }
        }

        const apps = everything.map(app => ({ app: app, score: score(app, wanted) })).filter(match => match.score > 0);
        apps.sort((a, b) => b.score - a.score || byUse(a.app, b.app));
        return found.concat(apps.map(match => appEntry(match.app))).slice(0, Config.launcherStars);
    }

    function launch(app, page) {
        const next = Object.assign({}, uses);
        next[app.id] = (next[app.id] ?? 0) + 1;
        uses = next;
        memory.setText(JSON.stringify(next));
        open = false;
        if (page) {
            Planet.request(page);
            pending = app;
            afterSpin.restart();
        } else {
            app.execute();
        }
    }

    function run(entry) {
        open = false;
        switch (entry.kind) {
        case "app":
            launch(entry.app);
            break;
        case "window":
            Planet.request(entry.window.workspace?.id ?? Planet.current);
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${entry.window.address}" })`);
            break;
        case "sum":
            copier.exec(["wl-copy", entry.value]);
            break;
        case "command":
            Hyprland.dispatch(`hl.dsp.exec_cmd(${JSON.stringify(entry.command)})`);
            break;
        }
    }

    property var pending: null

    // Dropped on another page: arrive there first, then open it
    Timer {
        id: afterSpin

        interval: Theme.pageSpin + 200
        onTriggered: root.pending?.execute()
    }

    Process {
        id: copier
    }

    // Remembered between sessions, so the launcher learns your habits
    FileView {
        id: memory

        path: Quickshell.statePath("apps.json")
        onLoaded: {
            try {
                root.uses = JSON.parse(text());
            } catch (error) {
                root.uses = {};
            }
        }
    }
}
