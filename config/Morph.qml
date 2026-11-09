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
//
// Relief, a new form for the ground, runs in as a front from where it was touched, both
// ways along the ridges; the land sinks past the screen's edge when the hills go, and
// rises again when they come back.
//
// Astres, what hangs in a world's sky, never fade: the old ones set behind the far ridge
// as the new ones rise from it.
Singleton {
    id: root

    readonly property var tints: ["skyTop", "skyMid", "skyLow", "terrain", "light", "deep", "brightness"]
    // A world is strata stacked by altitude, each a named group of its keys, so any world
    // can take any stratum from any other
    readonly property var strata: [
        { id: "allure", label: Lang.t("Allure"), keys: ["style"] },
        { id: "astres", label: Lang.t("Astres"), keys: ["scenery"] },
        { id: "ciel", label: Lang.t("Ciel"), keys: ["sky"] },
        { id: "soleil", label: Lang.t("Soleil"), keys: ["sun", "cut"] },
        { id: "teintes", label: Lang.t("Teintes"), keys: ["skyTop", "skyMid", "skyLow", "terrain", "light", "deep", "brightness"] },
        { id: "relief", label: Lang.t("Relief"), keys: ["form", "seed", "relief", "rough", "ground"] }
    ]
    readonly property var forms: ["ridges", "tables", "dunes"]
    property bool tinted: false // this change brings new colours
    property bool reshaped: false // and a new form for the ground
    property real front: 0 // how far a re-form has run, 0 to 1
    property real reformAt: 0 // the angle on screen it starts from
    property real sink: 0 // how far the land has sunk, while the hills go or come back
    property bool sinking: false
    property bool restaged: false // and what hangs in its sky changes
    property real setting: 0 // how far the old bodies have set, 0 to 1
    property real rising: 1 // how far the new ones have risen

    property string planetId: ""
    property var from: null // the world as it was on screen
    property var to: null // and as it is now
    property bool dusk: false
    property real tint: 0 // how far the edge has gone, 0 to 1
    property bool rehearsal: false // plays the change there and back without keeping it
    property bool rehearsalBack: false
    readonly property bool busy: tinting.running || pause.running || reforming.running || sinkingAway.running || bodies.running
    // The edge reaches the bar about here: the dome's top passes the screen's top at
    // 0.84 of the way, and a dusk's leaves it at 0.16
    readonly property bool crossed: dusk ? tint >= 0.16 : tint >= 0.84

    // The world as the rest of the shell should show it right now: as it was until the
    // edge reaches the bar
    function shown(planet) {
        if (!busy || !tinted || !planet || planet.id !== planetId)
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

    // A ground form by number, for the shader: 0 ridges, 1 tables, 2 dunes
    function formOf(planet, depth) {
        return Math.max(0, forms.indexOf(planet?.form?.[depth] ?? "ridges"));
    }

    function changesForm(a, b) {
        return formOf(a, "far") !== formOf(b, "far") || formOf(a, "near") !== formOf(b, "near");
    }

    // Changes a world: `changes` are its new keys; `reset` puts back a list of keys, or
    // everything when it's true. `at` is the angle on screen a re-form starts from.
    function apply(id, changes, reset, at) {
        hurry();
        reformAt = at ?? 0;
        const before = Object.assign({}, Planets.find(id));
        if (reset)
            Planets.untweak(id, reset === true ? undefined : reset);
        if (changes)
            Planets.tweak(id, changes);
        start(id, before, Object.assign({}, Planets.find(id)));
    }

    // Takes strata from another world, all of them when none are named, as one change. The
    // world remembers where each came from.
    function borrow(id, other, ids, onlyRehearse) {
        const source = Planets.find(other), planet = Planets.find(id), changes = {};
        const taken = strata.filter(stratum => !ids || ids.includes(stratum.id));
        for (const stratum of taken) {
            for (const key of stratum.keys)
                changes[key] = source[key];
        }
        const borrowed = Object.assign({}, planet.borrowed ?? {});
        for (const stratum of taken)
            borrowed[stratum.id] = other;
        changes.borrowed = borrowed;
        // A key the other world doesn't have goes back to how this one came
        const reset = taken.reduce((keys, stratum) => keys.concat(stratum.keys), []).filter(key => source[key] === undefined);
        for (const key of reset)
            delete changes[key];
        if (onlyRehearse) {
            const original = Planets.original(id) ?? {};
            for (const key of reset)
                changes[key] = original[key];
            rehearse(id, changes);
        } else {
            apply(id, changes, reset.length ? reset : null);
        }
    }

    // A stratum back to how the world came
    function revert(id, stratumId) {
        const stratum = strata.find(s => s.id === stratumId);
        const borrowed = Object.assign({}, Planets.find(id).borrowed ?? {});
        delete borrowed[stratumId];
        apply(id, { borrowed: borrowed }, stratum.keys);
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
        tinted = changesTint(before, after);
        reshaped = changesForm(before, after);
        sinking = Planets.groundOf(before) !== Planets.groundOf(after);
        restaged = Planets.sceneOf(before) !== Planets.sceneOf(after);
        if (!tinted && !reshaped && !sinking && !restaged)
            return;
        planetId = id;
        from = before;
        to = after;
        if (tinted) {
            // Below a small difference it's always a dawn: two sets about as bright
            dusk = brightness(after) < brightness(before) - 0.04;
            tinting.duration = 1200 * Theme.pace;
            tinting.restart();
        }
        if (reshaped) {
            reforming.duration = 900 * Theme.pace;
            reforming.restart();
        }
        if (restaged) {
            // A swap overlaps the two: the new one starts as the old one is on its way down
            const both = Planets.sceneOf(before) !== "" && Planets.sceneOf(after) !== "";
            setting = 0;
            rising = 0;
            settingAway.duration = Planets.sceneOf(before) !== "" ? 480 * Theme.pace : 0;
            risingUp.duration = Planets.sceneOf(after) !== "" ? 720 * Theme.pace : 0;
            gap.duration = both ? 240 * Theme.pace : 0;
            bodies.restart();
        }
        if (sinking) {
            sinkingAway.from = Planets.groundOf(before) ? 0 : 1;
            sinkingAway.to = Planets.groundOf(after) ? 0 : 1;
            sinkingAway.duration = 600 * Theme.pace;
            sinkingAway.restart();
        }
    }

    // The front and the sinking finish together with the colours, if any
    function settleWhenDone() {
        if (tinting.running || pause.running || reforming.running || sinkingAway.running || bodies.running)
            return;
        if (rehearsal && !rehearsalBack)
            pause.restart();
        else
            settle();
    }

    // A new pick never waits: whatever runs finishes now
    function hurry() {
        pause.stop();
        for (const animation of [tinting, reforming, sinkingAway, bodies]) {
            if (animation.running)
                animation.complete();
        }
    }

    NumberAnimation {
        id: tinting

        target: root
        property: "tint"
        from: 0
        to: 1
        easing.type: Easing.InOutSine
        onFinished: root.settleWhenDone()
    }

    NumberAnimation {
        id: reforming

        target: root
        property: "front"
        from: 0
        to: 1
        onFinished: root.settleWhenDone()
    }

    ParallelAnimation {
        id: bodies

        NumberAnimation {
            id: settingAway

            target: root
            property: "setting"
            from: 0
            to: 1
            easing.type: Easing.InCubic
        }
        SequentialAnimation {
            PauseAnimation {
                id: gap
            }
            NumberAnimation {
                id: risingUp

                target: root
                property: "rising"
                from: 0
                to: 1
                easing.type: Easing.OutCubic
            }
        }
        onFinished: root.settleWhenDone()
    }

    NumberAnimation {
        id: sinkingAway

        target: root
        property: "sink"
        easing.type: Easing.InOutCubic
        onFinished: root.settleWhenDone()
    }

    // A rehearsal goes back the other way after a moment
    Timer {
        id: pause

        interval: 700
        onTriggered: {
            root.rehearsalBack = true;
            root.start(root.planetId, root.to, root.from);
        }
    }

    function settle() {
        tint = 0;
        front = 0;
        sink = 0;
        tinted = false;
        reshaped = false;
        sinking = false;
        restaged = false;
        setting = 0;
        rising = 1;
        from = null;
        to = null;
        rehearsal = false;
        rehearsalBack = false;
        planetId = "";
    }
}
