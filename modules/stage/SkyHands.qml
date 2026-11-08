import QtQuick
import qs.config
import qs.services

// Your hands at the edge of the air. Drag anywhere and the belt turns with you round the
// planet, 1:1; let go and it carries on a little, then settles on a moon. A click on a
// moon turns it to the top. The wheel turns it a moon a notch; two fingers follow 1:1.
// A click on your page or the planet, or the right button, takes you back down.
MouseArea {
    id: root

    property point center // the planet's centre, in pixels
    property real planetRadius
    property real unit: width / 1600
    property real grow: 1
    property rect card // your page, standing on the planet

    readonly property real beltRadius: Theme.skyBelt * planetRadius
    readonly property real stepAngle: 11 * Math.PI / 180 // one moon along the belt
    property point pressedAt
    property real lastAngle: 0
    property real lastTime: 0
    property real speed: 0 // moons a second
    property bool turning: false
    property bool scrubbing: false // along the vernier, from one end of the folder to the other
    readonly property real spread: 52 * Math.PI / 180

    // The vernier's tick under the pointer, along the limb, or -1
    function tickAt(x, y) {
        const r = Math.hypot(x - center.x, y - center.y), angle = angleAt(x, y);
        if (r < planetRadius || r > planetRadius + 30 * unit || Math.abs(angle) > spread + 0.02)
            return -1;
        return Math.max(0, Math.min(Skies.count - 1, Math.round((angle + spread) / (2 * spread) * (Skies.count - 1))));
    }

    function angleAt(x, y) {
        return Math.atan2(x - center.x, center.y - y);
    }

    function wrap(angle) {
        return Math.atan2(Math.sin(angle), Math.cos(angle));
    }

    // Which place on the belt is under the pointer, counted from the zenith, or null
    function moonAt(x, y) {
        const top = Math.round(Skies.scroll);
        for (let k = -6; k <= 6; k++) {
            const place = Skies.placeOf(top + k - Skies.scroll, center, beltRadius, unit, grow, width / height);
            const dx = Math.abs(x - place.x) / place.aspect, dy = Math.abs(y - place.y);
            const e = place.exponent, reach = place.halfHeight + 6 * unit;
            if (Math.pow(Math.pow(dx, e) + Math.pow(dy, e), 1 / e) <= reach)
                return k;
        }
        return null;
    }

    function onCard(x, y) {
        return x >= card.x && x <= card.x + card.width && y >= card.y && y <= card.y + card.height;
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: turning ? Qt.ClosedHandCursor : Skies.hovered >= 0 ? Qt.PointingHandCursor : Qt.OpenHandCursor

    onExited: Skies.hovered = -1

    onPressed: mouse => {
        pressedAt = Qt.point(mouse.x, mouse.y);
        lastAngle = angleAt(mouse.x, mouse.y);
        lastTime = Date.now();
        speed = 0;
        turning = false;
        scrubbing = tickAt(mouse.x, mouse.y) >= 0;
    }

    onPositionChanged: mouse => {
        if (!pressed) {
            const k = moonAt(mouse.x, mouse.y);
            Skies.hovered = k === null ? -1 : Skies.wrap(Skies.zenith + k);
            return;
        }
        if (scrubbing) {
            const r = Math.hypot(mouse.x - center.x, mouse.y - center.y);
            const tick = Math.max(0, Math.min(Skies.count - 1, Math.round((angleAt(mouse.x, mouse.y) + spread) / (2 * spread) * (Skies.count - 1))));
            if (r > planetRadius * 0.8 && tick !== Skies.zenith)
                Skies.flyTo(tick);
            return;
        }
        if (!turning && Math.hypot(mouse.x - pressedAt.x, mouse.y - pressedAt.y) > 8) {
            turning = true;
            Skies.hovered = -1;
            Skies.holdTurn();
        }
        if (!turning)
            return;
        const angle = angleAt(mouse.x, mouse.y), now = Date.now();
        const moons = -wrap(angle - lastAngle) / stepAngle;
        Skies.turnBy(moons);
        speed = moons / Math.max(1, now - lastTime) * 1000;
        lastAngle = angle;
        lastTime = now;
    }

    onReleased: mouse => {
        if (scrubbing) {
            const tick = tickAt(mouse.x, mouse.y);
            if (tick >= 0 && tick !== Skies.zenith)
                Skies.flyTo(tick);
            scrubbing = false;
            return;
        }
        if (turning) {
            // Held still before letting go, it just settles where it is
            Skies.fling(Date.now() - lastTime > 120 ? 0 : speed);
            turning = false;
            return;
        }
        if (mouse.button === Qt.RightButton) {
            Skies.leave();
            return;
        }
        const k = moonAt(mouse.x, mouse.y);
        if (k !== null && k !== 0)
            Skies.glideTo(Math.round(Skies.scroll) + k, 520 * (0.75 + 0.25 * Math.min(Math.abs(k), 5)), Easing.InOutSine);
        else if (k === null && (onCard(mouse.x, mouse.y) || Math.hypot(mouse.x - center.x, mouse.y - center.y) < planetRadius))
            Skies.leave(); // your page, or the planet under it
    }

    // A mouse wheel turns it a moon a notch; two fingers on a touchpad follow 1:1, and it
    // settles on a moon once they lift
    onWheel: wheel => {
        if (wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0) {
            const along = Math.abs(wheel.pixelDelta.x) > Math.abs(wheel.pixelDelta.y) ? -wheel.pixelDelta.x : -wheel.pixelDelta.y;
            Skies.turnBy(along / (beltRadius * stepAngle));
            settle.restart();
        } else {
            const notch = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y;
            Skies.step(notch > 0 ? -1 : 1);
        }
    }

    Timer {
        id: settle

        interval: 120
        onTriggered: Skies.fling(0)
    }
}
