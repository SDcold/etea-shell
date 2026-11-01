pragma Singleton

import QtQuick
import Quickshell

// Everything that has reached us, and what's currently on screen.
Singleton {
    id: root

    property var log: [] // newest first, what the journal shows
    property var popups: [] // on screen right now
    property bool journalOpen: false
    property bool quiet: false // do not disturb: notifications go straight to the journal

    readonly property int count: log.length

    function add(notification) {
        const entry = { notification: notification, time: new Date() };
        notification.closed.connect(() => forget(entry));
        log = [entry].concat(log);
        if (!quiet && !journalOpen)
            popups = [entry].concat(popups).slice(0, 4);
    }

    function hide(entry) {
        popups = popups.filter(other => other !== entry);
    }

    function forget(entry) {
        log = log.filter(other => other !== entry);
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
