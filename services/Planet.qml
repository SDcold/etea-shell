pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// The brain of the page rotation. Stand-ins take the place of the real windows,
// Hyprland switches page behind them, and the planet spins them into view.
Singleton {
    id: root

    enum Phase {
        Idle,
        Preparing,
        Spinning,
        Settling
    }

    readonly property real step: Math.PI * 2 / Config.pages
    readonly property int current: Hyprland.focusedWorkspace?.id ?? 1

    property int phase: Planet.Phase.Idle
    property real resting: 0 // where the planet sits between two transitions
    property real travel: 0 // how far it has turned so far
    property real distance: 0 // how far it has to turn in total
    readonly property real remaining: distance - travel

    property var leaving: []
    property var leavingNext: []
    property var arriving: []
    property int captured: 0
    property int expected: 0
    property real sceneOpacity: 1

    property int origin: 1
    property int target: 0
    property int queued: 0
    property var layouts: ({}) // what each page looked like when we last took its photo
    property bool arrivalKnown: false
    property real pressedAt: 0

    signal photoNeeded(int page)
    signal finished(real prepareMs)

    // Everything that wants to change page comes through here
    function request(page) {
        if (page < 1 || page > Config.pages)
            return;
        if (phase !== Planet.Phase.Idle) {
            queued = page;
            return;
        }
        if (page === current)
            return;

        origin = current;
        target = page;
        pressedAt = Date.now();
        captured = 0;
        phase = Planet.Phase.Preparing;
        Hyprland.refreshToplevels();
        geometryDelay.restart();
    }

    function requestNext(direction) {
        request((current - 1 + direction + Config.pages) % Config.pages + 1);
    }

    // Stacked the way they are on screen, and a maximized window hides the others
    function windowsOn(page) {
        const list = Hyprland.toplevels.values.filter(t => t.workspace?.id === page && t.lastIpcObject?.size);
        const full = list.find(t => t.lastIpcObject.fullscreen > 0);
        if (full)
            return [full];
        return list.sort((a, b) => b.lastIpcObject.focusHistoryID - a.lastIpcObject.focusHistoryID);
    }

    // Two photos match if the same windows sit in the same places
    function layoutOf(windows) {
        return windows.map(t => `${t.address} ${t.lastIpcObject.at} ${t.lastIpcObject.size}`).join("|");
    }

    function noteCaptured() {
        captured += 1;
        if (phase === Planet.Phase.Preparing && captured >= expected)
            begin();
    }

    // Stand-ins are ready, so show them, then let Hyprland switch behind them
    function begin() {
        if (phase !== Planet.Phase.Preparing)
            return;
        captureTimeout.stop();
        // The stand-ins leaving are cut from the photo, so they wait until it exists
        leaving = leavingNext;
        phase = Planet.Phase.Spinning;
        coverDelay.restart();
    }

    function settle() {
        // The old page has left the screen. Drop it now, or it snaps back to the
        // centre once the counters reset, and an empty page wouldn't hide it.
        leaving = [];
        resting += distance;
        distance = 0;
        travel = 0;
        phase = Planet.Phase.Settling;
        revealDelay.restart();
    }

    function reset() {
        leaving = [];
        arriving = [];
        sceneOpacity = 1;
        phase = Planet.Phase.Idle;
        if (queued && queued !== current) {
            const next = queued;
            queued = 0;
            request(next);
        }
        queued = 0;
    }

    // Shortest way round, so going from page 6 to page 1 is a single step
    function shortestSteps(from, to) {
        const pages = Config.pages;
        const steps = ((to - from) % pages + pages) % pages;
        return steps > pages / 2 ? steps - pages : steps;
    }

    // Give the window list a moment to come back from Hyprland
    Timer {
        id: geometryDelay

        interval: 12
        onTriggered: {
            root.distance = root.shortestSteps(root.origin, root.target) * root.step;
            const leaving = root.windowsOn(root.origin);
            root.leavingNext = leaving;
            root.arriving = root.windowsOn(root.target);

            // Coming back to a page that hasn't changed? Its old photo is still good
            const arrival = root.layoutOf(root.arriving);
            root.arrivalKnown = root.arriving.length > 0 && root.layouts[root.target] === arrival;
            root.expected = (leaving.length ? 1 : 0) + (root.arrivalKnown ? 0 : root.arriving.length);

            if (leaving.length) {
                root.layouts[root.origin] = root.layoutOf(leaving);
                root.photoNeeded(root.origin);
            }
            if (root.expected === 0)
                root.begin();
            else
                captureTimeout.restart();
        }
    }

    // A window that refuses to be captured should never hold the page back
    Timer {
        id: captureTimeout

        interval: 120
        onTriggered: root.begin()
    }

    // Two frames for the stand-ins to reach the screen before the swap
    Timer {
        id: coverDelay

        interval: 34
        onTriggered: {
            root.finished(Date.now() - root.pressedAt);
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${root.target} })`);
            spin.duration = Math.max(1, Theme.pageSpin * (0.75 + 0.25 * Math.abs(root.distance / root.step)));
            spin.from = 0;
            spin.to = root.distance;
            spin.start();
        }
    }

    NumberAnimation {
        id: spin

        target: root
        property: "travel"
        easing.type: Easing.InOutCubic
        onFinished: root.settle()
    }

    // The wallpaper behind has to catch up before we pull the scene away
    Timer {
        id: revealDelay

        interval: 24
        onTriggered: fade.start()
    }

    NumberAnimation {
        id: fade

        target: root
        property: "sceneOpacity"
        from: 1
        to: 0
        duration: Theme.pageReveal
        onFinished: root.reset()
    }

    // If something else moved us, like a gesture, just follow along
    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            if (root.phase === Planet.Phase.Idle)
                root.resting = (root.current - 1) * root.step;
        }
    }

    Component.onCompleted: resting = (current - 1) * step
}
