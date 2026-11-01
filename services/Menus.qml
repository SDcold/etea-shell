pragma Singleton

import QtQuick
import Quickshell

// Which bar menu is open, and where it should hang from.
Singleton {
    property string open: ""
    property real anchorX: 0

    function toggle(name, x) {
        anchorX = x;
        open = open === name ? "" : name;
    }
}
