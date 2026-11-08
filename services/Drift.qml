pragma Singleton

import QtQuick
import Quickshell

// One clock for every card's living sky. It runs at the screen's own rate, never in steps,
// and ticking together means one redraw for all the cards on screen instead of one each.
Singleton {
    id: root

    property int listeners: 0
    property real time: 0

    function join() {
        listeners += 1;
        run();
    }

    function leave() {
        listeners = Math.max(0, listeners - 1);
        run();
    }

    // An hour at a time, picked up from wherever the clock stopped
    function run() {
        if (listeners > 0 && !clock.running) {
            clock.to = time + 3600;
            clock.start();
        } else if (listeners === 0) {
            clock.stop();
        }
    }

    NumberAnimation {
        id: clock

        target: root
        property: "time"
        duration: 3600000
        onFinished: root.run()
    }
}
