pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Everything that has reached us, and what's currently on screen. The journal and the
// do not disturb switch outlive a restart: each entry keeps a copy of what it said, since
// the live notification and its buttons are gone once the shell restarts.
Singleton {
    id: root

    property var log: [] // newest first, what the journal shows
    property var popups: [] // on screen right now
    readonly property bool journalOpen: Menus.rightOpen // the control centre lists them already
    property alias quiet: saved.quiet // do not disturb: notifications go straight to the journal
    readonly property int keep: 60 // how many the journal remembers

    readonly property int count: log.length

    // The journal by app, the app that spoke last first
    readonly property var groups: {
        const found = [];
        for (const entry of log) {
            const app = entry.notification?.appName || entry.saved?.appName || "";
            const group = found.find(other => other.app === app);
            group ? group.entries.push(entry) : found.push({ app: app, entries: [entry] });
        }
        return found;
    }

    // Lists hand their items to QML as copies, so an entry is known by its number, never by itself
    property int lastId: 0

    function copy(notification) {
        const image = notification.image ?? "";
        return {
            appName: notification.appName ?? "",
            appIcon: notification.appIcon ?? "",
            summary: notification.summary ?? "",
            body: notification.body ?? "",
            // Pictures held in memory don't survive a restart, files do
            image: image.startsWith("file://") || image.startsWith("/") ? image : "",
            urgency: notification.urgency,
            actions: [],
            expireTimeout: 0
        };
    }

    function add(notification) {
        lastId += 1;
        const entry = { id: lastId, notification: notification, saved: copy(notification), time: new Date() };
        notification.closed.connect(() => forget(entry));
        log = [entry].concat(log).slice(0, keep);
        if (!quiet && !journalOpen)
            popups = [entry].concat(popups).slice(0, 4);
    }

    function hide(entry) {
        popups = popups.filter(other => other.id !== entry.id);
    }

    function forget(entry) {
        log = log.filter(other => other.id !== entry.id);
        hide(entry);
    }

    function dismiss(entry) {
        forget(entry);
        entry.notification?.dismiss();
    }

    function clear(app) {
        log.slice().filter(entry => app === undefined || (entry.notification?.appName || entry.saved?.appName || "") === app).forEach(dismiss);
    }

    onLogChanged: saveSoon.restart()

    Timer {
        id: saveSoon

        interval: 600
        onTriggered: {
            saved.entries = root.log.map(entry => ({ id: entry.id, time: entry.time.toISOString(), saved: entry.saved }));
            file.writeAdapter();
        }
    }

    FileView {
        id: file

        path: Quickshell.statePath("notifications.json")
        onLoaded: {
            const restored = saved.entries.map(entry => ({ id: entry.id, notification: null, saved: entry.saved, time: new Date(entry.time) }));
            root.lastId = Math.max(root.lastId, ...restored.map(entry => entry.id));
            root.log = root.log.concat(restored).slice(0, root.keep);
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: saved

            property var entries: []
            property bool quiet: false

            onQuietChanged: file.writeAdapter()
        }
    }
}
