pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The colours of every picture, read once from its thumbnail and remembered between
// sessions. One quantizer works through a queue, nearest wish first, and is never pointed
// at a new picture while it is still busy: stopping one mid-way blocks the whole interface.
Singleton {
    id: root

    property var known: ({}) // md5(path + mtime) → { palette, dominant }
    property var queue: [] // pictures still to read, the most wanted first
    property var reading: null
    property int version: 0 // grows with each palette learnt, for bindings to follow

    signal learnt(string path)

    function keyOf(picture) {
        return Qt.md5(picture.path + picture.mtime);
    }

    // Its palette if known; otherwise it's put first in line and arrives with `learnt`
    function of(picture) {
        const found = known[keyOf(picture)];
        if (found)
            return found;
        want(picture, true);
        return null;
    }

    function want(picture, first) {
        const key = keyOf(picture);
        if (known[key] || reading && keyOf(reading) === key)
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
        quantizer.source = Pictures.quickest(reading.path);
        giveUp.restart();
    }

    function done(colors) {
        const picture = reading;
        giveUp.stop();
        reading = null;
        if (picture && colors.length >= 2) {
            const palette = Forge.paletteOf(colors);
            if (palette) {
                known[keyOf(picture)] = { palette: palette, dominant: dominantOf(colors) };
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

    ColorQuantizer {
        id: quantizer

        depth: 4
        rescaleSize: 64
        onColorsChanged: {
            if (root.reading)
                root.done(colors);
        }
    }

    // A picture that can't be read is skipped rather than holding up the line
    Timer {
        id: giveUp

        interval: 3000
        onTriggered: root.done([])
    }

    Timer {
        id: save

        interval: 2000
        onTriggered: memory.setText(JSON.stringify(root.known))
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
