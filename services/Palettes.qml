pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The colours of every picture, read once from its thumbnail and remembered between
// sessions. Pictures are read one at a time through a queue, nearest wish first. Each gets a
// quantizer of its own, so its colours can only ever be its own: one quantizer pointed at
// picture after picture answers first with an empty list, then with colours that arrive
// after it has moved on. A quantizer is never stopped mid-way either: that blocks the
// whole interface.
Singleton {
    id: root

    // md5(path + mtime) → { colors, dominant }: the colours as read, kept between sessions.
    // The palette is worked out from them when asked, so it follows Forge's rules as they are.
    property var known: ({})
    readonly property int rules: 2 // what's known from an earlier way of reading is read again
    property var queue: [] // pictures still to read, the most wanted first
    property var reading: null
    property var quantizer: null // the one reading it
    property int version: 0 // grows with each palette learnt, for bindings to follow

    signal learnt(string path)

    function keyOf(picture) {
        return Qt.md5(picture.path + picture.mtime);
    }

    // { palette, dominant } if known; otherwise it's put first in line and arrives with `learnt`
    function of(picture) {
        const found = known[keyOf(picture)];
        if (found?.colors && found.rules === rules) {
            if (found.palette?.made !== Forge.paletteMade)
                found.palette = Forge.paletteOf(found.colors.map(color => Qt.color(color)));
            return found;
        }
        Qt.callLater(want, picture, true); // not from inside whatever binding is asking
        return null;
    }

    function want(picture, first) {
        const key = keyOf(picture);
        if (known[key]?.rules === rules || reading && keyOf(reading) === key)
            return;
        const rest = queue.filter(p => keyOf(p) !== key);
        queue = first ? [picture].concat(rest) : rest.concat([picture]);
        next();
    }

    function next() {
        if (reading || queue.length === 0)
            return;
        reading = queue[0];
        queue = queue.slice(1);
        quantizer = reader.createObject(root, { picture: reading, source: Pictures.quickest(reading.path) });
        giveUp.restart();
    }

    // A quantizer has answered for its own picture; one given up on is just let go
    function done(from, colors) {
        if (colors.length < 2)
            return; // the empty list it starts with: stopping it now would block everything
        from.destroy();
        if (from !== quantizer)
            return;
        const picture = from.picture;
        giveUp.stop();
        quantizer = null;
        reading = null;
        if (colors.length >= 2) {
            const palette = Forge.paletteOf(colors);
            if (palette) {
                known[keyOf(picture)] = { colors: colors.map(color => String(color)), rules: rules, palette: palette, dominant: dominantOf(colors) };
                version += 1;
                save.restart();
                learnt(picture.path);
            }
        }
        next();
    }

    // The colour that stands for a picture on a strip of ticks: vivid, and not too dark
    function dominantOf(colors) {
        let best = colors[0], score = -1;
        for (const color of colors) {
            const value = color.hsvSaturation * color.hsvValue + 0.15 * color.hsvValue;
            if (value > score) {
                score = value;
                best = color;
            }
        }
        return String(best);
    }

    Component {
        id: reader

        ColorQuantizer {
            property var picture

            depth: 4
            rescaleSize: 64
            onColorsChanged: root.done(this, colors)
        }
    }

    // A picture that can't be read is skipped rather than holding up the line. Its quantizer
    // is left to finish on its own, and dropped when it answers.
    Timer {
        id: giveUp

        interval: 3000
        onTriggered: {
            root.quantizer = null;
            root.reading = null;
            root.next();
        }
    }

    Timer {
        id: save

        interval: 2000
        onTriggered: memory.setText(JSON.stringify(root.known, (key, value) => key === "palette" ? undefined : value))
    }

    FileView {
        id: memory

        path: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/etea/palettes.json`
        onLoaded: {
            try {
                root.known = Object.assign(JSON.parse(text()), root.known);
                root.version += 1;
            } catch (error) {
                root.known = root.known;
            }
        }
    }
}
