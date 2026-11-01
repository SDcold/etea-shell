import QtQuick
import qs.config
import qs.modules.bar

// The stars on a window's frame. They sit right on Hyprland's rounded border,
// and the real window and its stand-in both use this, so they line up exactly.
Item {
    id: root

    required property string seed
    required property real windowWidth
    required property real windowHeight

    // A little repeatable randomness, so a window keeps its constellation
    function randomFrom(text) {
        let state = 7;
        for (let i = 0; i < text.length; i++)
            state = (state * 31 + text.charCodeAt(i)) % 2147483647;
        return () => (state = state * 16807 % 2147483647) / 2147483647;
    }

    // A dialog shouldn't wear the same stars as a full window
    readonly property real fit: Math.max(0.5, Math.min(1, Math.min(windowWidth, windowHeight) / Theme.traceFullSizeAt))

    readonly property var stars: {
        const w = windowWidth, h = windowHeight;
        if (w <= 0 || h <= 0)
            return [];

        const random = randomFrom(seed);
        const line = Theme.traceWidth / 2;
        // The middle of the border, out at the tip of each rounded corner
        const corner = Theme.windowRadius - (Theme.windowRadius + line) * Math.SQRT1_2;
        const points = [[corner, corner], [w - corner, corner], [w - corner, h - corner], [corner, h - corner]].map(([x, y]) => ({ x: x, y: y, size: Theme.traceCornerStar }));

        // Stars along a straight side, spaced unevenly on purpose
        const along = (length, place) => {
            const usable = length - Theme.windowRadius * 2;
            const count = Math.max(1, Math.round(usable / Theme.traceSpacing));
            for (let i = 0; i < count; i++) {
                const t = (i + 0.5 + (random() - 0.5) * 0.6) / count;
                points.push(Object.assign(place(Theme.windowRadius + usable * t), { size: Theme.traceEdgeStar * (0.8 + random() * 0.4) }));
            }
        };
        along(w, x => ({ x: x, y: -line }));
        along(w, x => ({ x: x, y: h + line }));
        along(h, y => ({ x: -line, y: y }));
        along(h, y => ({ x: w + line, y: y }));
        return points;
    }

    Repeater {
        model: root.stars

        Star {
            required property var modelData

            x: modelData.x - size
            y: modelData.y - size
            size: modelData.size * Theme.traceStarScale * root.fit
            lit: true
            animated: false
        }
    }
}
