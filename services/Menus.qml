pragma Singleton

import QtQuick
import Quickshell

// Which bar menu is open, and where it should hang from.
Singleton {
    property string open: ""
    property real anchorX: 0

    property string lastClosed: ""
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
