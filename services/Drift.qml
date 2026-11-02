pragma Singleton

import QtQuick
import Quickshell

// One clock for every card's living sky. Their nebulae drift about two pixels a second,
// so fifteen steps a second is already smooth, and ticking together means one redraw
// for all the cards on screen instead of one each.
Singleton {
    id: root

    property int listeners: 0
    property real time: 0

    function join() {
        listeners += 1;
    }

    function leave() {
        listeners = Math.max(0, listeners - 1);
    }

    Timer {
        running: root.listeners > 0
        repeat: true
        interval: 66
        onTriggered: root.time += 0.066
    }
}
