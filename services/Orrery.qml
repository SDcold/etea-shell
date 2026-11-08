pragma Singleton

import QtQuick
import Quickshell

// One clock for whatever drifts across a world's sky. It only counts while the page is
// empty and nothing is moving, so every copy of a world reads the same time, and a body
// covered by windows picks up exactly where it was when they go.
Singleton {
    id: root

    readonly property bool running: Planet.pageEmpty && Planet.phase === Planet.Phase.Idle
    property real banked: 0 // seconds counted before the last stop
    property real since: Date.now()

    // Seconds of sky time so far
    function now() {
        return banked + (running ? (Date.now() - since) / 1000 : 0);
    }

    onRunningChanged: {
        if (running)
            since = Date.now();
        else
            banked += (Date.now() - since) / 1000;
    }
}
