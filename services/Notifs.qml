pragma Singleton

import QtQuick
import Quickshell

// Everything that has reached us, and what's currently on screen.
Singleton {
    id: root

    property var log: [] // newest first, what the journal shows
    property var popups: [] // on screen right now
    readonly property bool journalOpen: Menus.rightOpen // the control centre lists them already
    property bool quiet: false // do not disturb: notifications go straight to the journal

    readonly property int count: log.length

    // Lists hand their items to QML as copies, so an entry is known by its number, never by itself
    property int lastId: 0

    function add(notification) {
        lastId += 1;
        const entry = { id: lastId, notification: notification, time: new Date() };
        notification.closed.connect(() => forget(entry));
        log = [entry].concat(log);
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

    function clear() {
        log.slice().forEach(dismiss);
    }
}
