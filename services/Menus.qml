pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Which bar menu is open, and where it should hang from.
Singleton {
    property string open: ""
    property real anchorX: 0
    property color tint: Theme.windowLit

    property bool settingsOpen: false
    property bool sessionOpen: false
    property string lastClosed: ""

    // The side panels, and the spot in the bar each one was poured out of
    property bool leftOpen: false
    property bool rightOpen: false
    property rect leftAnchor: Qt.rect(0, 0, 0, 0)
    property rect rightAnchor: Qt.rect(0, 0, 0, 0)
    property string panelClosed: ""
    property real panelClosedAt: 0

    // With no spot given, it was the keyboard: the panel finds its own way out
    function togglePanel(side, from) {
        if (side === panelClosed && Date.now() - panelClosedAt < 250)
            return;
        const isOpen = side === "left" ? leftOpen : rightOpen;
        if (isOpen) {
            closePanel(side);
            return;
        }
        open = "";
        if (side === "left") {
            leftAnchor = from ?? Qt.rect(0, 0, 0, 0);
            leftOpen = true;
        } else {
            rightAnchor = from ?? Qt.rect(0, 0, 0, 0);
            rightOpen = true;
        }
    }

    function closePanel(side) {
        panelClosed = side;
        panelClosedAt = Date.now();
        if (side === "left")
            leftOpen = false;
        else
            rightOpen = false;
    }
    property real closedAt: 0

    function toggle(name, x) {
        // Clicking a menu's own button closes it first, and that same click lands here
        // a moment later. Without this check it would pop straight back open.
        if (name === lastClosed && Date.now() - closedAt < 250)
            return;
        anchorX = x;
        if (open === name)
            close();
        else
            open = name;
    }

    function close() {
        lastClosed = open;
        closedAt = Date.now();
        open = "";
    }
}
