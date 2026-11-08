pragma Singleton

import QtQuick
import Quickshell

// A world changes where it lives, from its own cause, never by fading. Morph writes the
// change at once and keeps what was on screen, so everything showing that world plays
// the same move from the same clock, and a copy built in the middle joins in.
//
// Teintes, a new set of colours, arrives as a new day: a wide dome rises from under the
// horizon at the sun's place, the new colours inside, its edge a line of the new light.
// A darker set comes as a dusk: the old light shrinks back into the sun. The rest of the
// shell switches its light once, when the edge reaches the bar.
Singleton {
    id: root

    readonly property var tints: ["skyTop", "skyMid", "skyLow", "terrain", "light"]

    property string planetId: ""
    property var from: null // the world as it was on screen
    property var to: null // and as it is now
    property bool dusk: false
    property real tint: 0 // how far the edge has gone, 0 to 1
    property bool rehearsal: false // plays the change there and back without keeping it
    property bool rehearsalBack: false
    readonly property bool busy: tinting.running || pause.running || back.running
    // The edge reaches the bar about here: the dome's top passes the screen's top at
    // 0.84 of the way, and a dusk's leaves it at 0.16
    readonly property bool crossed: dusk ? tint >= 0.16 : tint >= 0.84

    // The world as the rest of the shell should show it right now: as it was until the
    // edge reaches the bar
    function shown(planet) {
        if (!busy || !planet || planet.id !== planetId)
            return planet;
        if (rehearsal && !rehearsalBack)
            return crossed ? to : planet;
        return crossed ? planet : from;
    }

    // How bright a set of colours is, so a darker one comes as a dusk
    function brightness(planet) {
        const c = Qt.color(planet.skyMid), l = Qt.color(planet.light);
        return 0.6 * (0.3 * c.r + 0.59 * c.g + 0.11 * c.b) + 0.4 * (0.3 * l.r + 0.59 * l.g + 0.11 * l.b);
    }

    function changesTint(a, b) {
        return tints.some(key => JSON.stringify(a[key]) !== JSON.stringify(b[key]));
    }

    // Changes a world: `changes` are its new keys; `reset` puts back a list of keys, or
    // everything when it's true
    function apply(id, changes, reset) {
        hurry();
        const before = Object.assign({}, Planets.find(id));
        if (reset)
            Planets.untweak(id, reset === true ? undefined : reset);
        if (changes)
            Planets.tweak(id, changes);
        start(id, before, Object.assign({}, Planets.find(id)));
    }

    // The same move, without writing anything: there, a moment, and back
    function rehearse(id, changes) {
        hurry();
        const before = Object.assign({}, Planets.find(id));
        rehearsal = true;
        rehearsalBack = false;
        start(id, before, Object.assign({}, before, changes));
    }

    function start(id, before, after) {
        if (!changesTint(before, after))
            return;
        planetId = id;
        from = before;
        to = after;
        // Below a small difference it's always a dawn: two sets about as bright
        dusk = brightness(after) < brightness(before) - 0.04;
        tinting.duration = 1200 * Theme.pace;
        tinting.restart();
    }

    // A new pick never waits: whatever runs finishes now
    function hurry() {
        if (tinting.running)
            tinting.complete();
        if (back.running)
            back.complete();
    }

    NumberAnimation {
        id: tinting

        target: root
        property: "tint"
        from: 0
        to: 1
        easing.type: Easing.InOutSine
        onFinished: {
            if (root.rehearsal && !root.rehearsalBack)
                pause.restart();
            else
                root.settle();
        }
    }

    // A rehearsal goes back the other way after a moment
    Timer {
        id: pause

        interval: 700
        onTriggered: {
            const there = root.to;
            root.rehearsalBack = true;
            root.to = root.from;
            root.from = there;
            root.dusk = root.brightness(root.to) < root.brightness(root.from) - 0.04;
            back.restart();
        }
    }

    NumberAnimation {
        id: back

        target: root
        property: "tint"
        from: 0
        to: 1
        duration: 1200 * Theme.pace
        easing.type: Easing.InOutSine
        onFinished: root.settle()
    }

    function settle() {
        tint = 0;
        from = null;
        to = null;
        rehearsal = false;
        rehearsalBack = false;
        planetId = "";
    }
}
