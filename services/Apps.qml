pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Every installed app, what you've been opening most, and how to find one.
Singleton {
    id: root

    property bool open: false
    property var uses: ({})

    readonly property var everything: DesktopEntries.applications.values.filter(app => !app.noDisplay)

    function usesOf(app) {
        return uses[app.id] ?? 0;
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

    // Nothing typed yet? Then your usual apps come first
    function search(text) {
        const wanted = text.trim().toLowerCase();
        if (!wanted)
            return everything.slice().sort((a, b) => usesOf(b) - usesOf(a) || a.name.localeCompare(b.name)).slice(0, Config.launcherStars);
        return everything.map(app => ({ app: app, score: score(app, wanted) })).filter(found => found.score > 0).sort((a, b) => b.score - a.score || usesOf(b.app) - usesOf(a.app) || a.app.name.localeCompare(b.app.name)).slice(0, Config.launcherStars).map(found => found.app);
    }

    function launch(app) {
        const next = Object.assign({}, uses);
        next[app.id] = (next[app.id] ?? 0) + 1;
        uses = next;
        memory.setText(JSON.stringify(next));
        app.execute();
        open = false;
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
