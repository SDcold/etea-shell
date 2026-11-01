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
        Settling,
        Orbit
    }

    readonly property real step: Math.PI * 2 / Config.pages
    readonly property int current: Hyprland.focusedWorkspace?.id ?? 1
    readonly property bool pageEmpty: Hyprland.toplevels.values.every(t => t.workspace?.id !== current)

    property int phase: Planet.Phase.Idle
    property real resting: 0 // where the planet sits between two transitions
    property real travel: 0 // how far it has turned so far
    property real distance: 0 // how far it has to turn in total
    readonly property real remaining: distance - travel

    property var leaving: []
    property var leavingNext: []
    property string birthing: "" // the window currently being born, if any
    property var arriving: []
    property int captured: 0
    property int expected: 0
    property real sceneOpacity: 1

    property int origin: 1
    // Altitude: 0 is the ground, 1 is orbit
    property real altitude: 0
    property var orbitPages: []
    property bool goingUp: false
    readonly property bool orbiting: phase === Planet.Phase.Orbit

    // One level above orbit: every planet you could live on
    property bool inSystem: false
    property real systemLevel: 0
    property real systemScroll: 0 // how far along the row of planets we are, between two of them while dragging
    readonly property int systemChoice: {
        const count = Planets.all.length;
        return (Math.round(systemScroll) % count + count) % count;
    }

    // Whatever comes to the front gets tried on by the whole shell
    onSystemChoiceChanged: {
        if (inSystem)
            Config.preview = Planets.all[systemChoice].id;
    }

    // Turning the planet by hand, up in orbit
    property real handTurn: 0
    property int hoveredPage: -1
    readonly property int topPage: ((origin - 1 - Math.round(handTurn / step)) % Config.pages + Config.pages) % Config.pages + 1

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

    // The middle of a page's constellation in the bar
    function pagePoint(page) {
        return Qt.point(Theme.barSide + (page - 1) * (Theme.pageWidth + Theme.pageGap) + Theme.pageWidth / 2, Theme.barGap + Theme.barHeight * 0.6);
    }

    // Going up: ground, then orbit, then the whole system, then back home
    function toggleOrbit() {
        if (phase === Planet.Phase.Idle)
            enterOrbit();
        else if (orbiting && !inSystem)
            enterSystem();
        else if (inSystem)
            land(Theme.planet.id);
    }

    // One level down at a time
    function goDown() {
        if (inSystem)
            leaveSystem();
        else if (orbiting)
            leaveOrbit(current);
    }

    function holdSpin() {
        spinShift.stop();
    }

    // Let go and the planet keeps going a little, then settles on the nearest page
    function fling(speed) {
        spinTo(Math.round((handTurn + speed * 0.28) / step) * step);
    }

    function nudge(steps) {
        spinTo((Math.round(handTurn / step) + steps) * step);
    }

    function spinTo(angle) {
        spinShift.stop();
        spinShift.to = angle;
        spinShift.start();
    }

    function refreshOrbit() {
        Hyprland.refreshToplevels();
        orbitRefresh.restart();
    }

    function enterSystem() {
        systemSlide.stop();
        systemScroll = Math.max(0, Planets.all.findIndex(planet => planet.id === Theme.planet.id));
        Config.preview = Planets.all[systemChoice].id;
        inSystem = true;
        systemShift.to = 1;
        systemShift.restart();
    }

    function leaveSystem() {
        Config.preview = "";
        inSystem = false;
        systemShift.to = 0;
        systemShift.restart();
    }

    function chooseStep(step) {
        slideSystemTo((systemSlide.running ? systemSlide.to : Math.round(systemScroll)) + step);
    }

    function slideSystemTo(position) {
        systemSlide.stop();
        systemSlide.to = position;
        systemSlide.start();
    }

    // The row of planets follows the hand, in planets rather than pixels
    function dragSystem(change) {
        systemSlide.stop();
        systemScroll += change;
    }

    // Let go and it carries on a little, then settles on the nearest planet
    function releaseSystem(speed) {
        slideSystemTo(Math.round(systemScroll + speed * 0.22));
    }

    // Moving to a new planet: the theme changes and we come down onto it
    function land(id) {
        Config.theme = id;
        leaveSystem();
        leaveOrbit(current);
    }

    // Same trick as a page change: photograph this page, then the stand-ins take over
    function enterOrbit() {
        origin = current;
        target = current;
        goingUp = true;
        captured = 0;
        phase = Planet.Phase.Preparing;
        Hyprland.refreshToplevels();
        orbitDelay.restart();
    }

    function beginOrbit() {
        captureTimeout.stop();
        goingUp = false;
        phase = Planet.Phase.Orbit;
        rise.restart();
    }

    // Going back down, turning to the chosen page on the way
    function leaveOrbit(page) {
        if (!orbiting || descent.running)
            return;
        target = page;
        spinShift.stop();
        rise.stop(); // going back down halfway up, the two movements mustn't fight
        const turn = shortestSteps(origin, page) * step + handTurn;
        distance = Math.atan2(Math.sin(turn), Math.cos(turn));
        // Letting go of the keyboard makes Hyprland refocus the old window, which would
        // pull us straight back to the old page. So let go first, then change page.
        phase = Planet.Phase.Spinning;
        descent.restart();
        if (page !== current)
            orbitLanding.restart();
    }

    // The pages stay up until the scene has stepped aside, or the windows would blink out.
    // From here on the page we landed on is the one at the top of the planet.
    function landed() {
        origin = target;
        // On an empty page Hyprland has nothing to focus and can drift back, so insist
        if (current !== target)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${target} })`);
        settle();
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
            goingUp ? beginOrbit() : begin();
    }

    // Stand-ins are ready, so show them, then let Hyprland switch behind them
    function begin() {
        if (phase !== Planet.Phase.Preparing)
            return;
        if (goingUp) {
            beginOrbit();
            return;
        }
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
        resting += distance - handTurn;
        handTurn = 0;
        hoveredPage = -1;
        distance = 0;
        travel = 0;
        phase = Planet.Phase.Settling;
        // Focus just moved behind the scene and takes a while to fade in.
        // Pulling the scene away before that shows the windows flickering as they catch up.
        revealDelay.interval = Math.max(24, Theme.windowFocusSpeed * 100 + 40 - Math.max(spin.duration, 0));
        revealDelay.restart();
    }

    function recover() {
        for (const animation of [spin, rise, descent, fade, spinShift, systemShift, systemSlide])
            animation.stop();
        for (const timer of [geometryDelay, orbitDelay, orbitLanding, captureTimeout, coverDelay, revealDelay])
            timer.stop();
        queued = 0;
        travel = 0;
        distance = 0;
        handTurn = 0;
        altitude = 0;
        systemLevel = 0;
        inSystem = false;
        goingUp = false;
        hoveredPage = -1;
        Config.preview = "";
        resting = (current - 1) * step;
        reset();
    }

    function reset() {
        leaving = [];
        arriving = [];
        orbitPages = [];
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

    Timer {
        id: orbitDelay

        interval: 12
        onTriggered: {
            const pages = [];
            for (let page = 1; page <= Config.pages; page++)
                pages.push(root.windowsOn(page));
            root.orbitPages = pages;

            const here = root.windowsOn(root.origin);
            root.expected = here.length ? 1 : 0;
            if (here.length) {
                root.layouts[root.origin] = root.layoutOf(here);
                root.photoNeeded(root.origin);
                captureTimeout.restart();
            } else {
                root.beginOrbit();
            }
        }
    }

    Timer {
        id: orbitLanding

        interval: 40
        onTriggered: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${root.target} })`)
    }

    // The scene covers every window while a transition runs, so a transition that gets
    // stuck would hide the whole desktop. However it went wrong, this gives the screen back.
    Timer {
        running: root.phase !== Planet.Phase.Idle && root.phase !== Planet.Phase.Orbit
        interval: 6000
        onTriggered: {
            console.warn("ETEA: transition stuck, giving the screen back");
            root.recover();
        }
    }

    NumberAnimation {
        id: spinShift

        target: root
        property: "handTurn"
        duration: 520
        easing.type: Easing.OutCubic
    }

    Timer {
        id: orbitRefresh

        interval: 160
        onTriggered: {
            const pages = [];
            for (let page = 1; page <= Config.pages; page++)
                pages.push(root.windowsOn(page));
            root.orbitPages = pages;
        }
    }

    NumberAnimation {
        id: systemSlide

        target: root
        property: "systemScroll"
        duration: 520
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.expressive
    }

    NumberAnimation {
        id: systemShift

        target: root
        property: "systemLevel"
        duration: 620
        easing.type: Easing.InOutCubic
    }

    NumberAnimation {
        id: rise

        target: root
        property: "altitude"
        from: 0
        to: 1
        duration: Theme.orbitRise
        easing.type: Easing.InOutCubic
    }

    ParallelAnimation {
        id: descent

        NumberAnimation {
            target: root
            property: "altitude"
            to: 0
            duration: Theme.orbitRise
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: root
            property: "travel"
            from: 0
            to: root.distance
            duration: Theme.orbitRise
            easing.type: Easing.InOutCubic
        }
        onFinished: root.landed()
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
