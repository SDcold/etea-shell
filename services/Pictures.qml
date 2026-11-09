pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The wallpapers in your Pictures folder, and their thumbnails. Picking one climbs to the
// belt of skies. Thumbnails come from the system's cache when another app already made them, x-large
// first, then from ours. Missing ones are made in the background by vips, one at a time,
// so the picture itself is only ever decoded while that job hasn't reached it yet.
Singleton {
    id: root

    property string folder: ""
    property var pictures: [] // { path, mtime }, newest first
    property bool listing: false
    // Which thumbnails already exist, so none is asked for in vain
    property var systemThumbs: ({}) // large, 256 px
    property var systemLarger: ({}) // x-large, 512 px
    property var ownThumbs: ({})

    readonly property string home: Quickshell.env("HOME")
    readonly property string thumbs: `${Quickshell.env("XDG_CACHE_HOME") || home + "/.cache"}/etea/thumbs`

    // A picture for something: answer(path) gets it. role says what for: "photo", "lock",
    // "newWorld", or "world" with planetId for another world's sky; item is the control that
    // asked, where the chosen picture flies home to.
    function pick(title, answer, options) {
        Skies.ask({ role: options?.role ?? "photo", title: title, answer: answer, item: options?.item ?? null, from: null, planetId: options?.planetId ?? Theme.planet.id });
    }

    function refresh() {
        listing = true;
        lister.running = true;
    }

    // Somewhere else: the system's own picker
    function browseThen(answer, title) {
        browser.answer = answer;
        browser.title = title ?? "";
        browser.running = true;
    }

    function url(path) {
        return "file://" + encodeURI(path).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    // Where a picture's thumbnail would be: the shared cache other apps fill, then ours
    function systemThumb(path, size) {
        return `${home}/.cache/thumbnails/${size ?? "large"}/${Qt.md5(url(path))}.png`;
    }

    function ownThumb(picture) {
        return `${thumbs}/${Qt.md5(picture.path + picture.mtime)}.jpg`;
    }

    // The smallest copy of a picture there is, for reading its colours quickly
    function quickest(path) {
        const picture = pictures.find(picture => picture.path === path);
        if (!picture)
            return url(path);
        const key = Qt.md5(url(path));
        if (systemThumbs[key])
            return url(systemThumb(path));
        if (ownThumbs[Qt.md5(path + picture.mtime)])
            return url(ownThumb(picture));
        return url(systemLarger[key] ? systemThumb(path, "x-large") : path);
    }

    // A thumbnail by stage: 0 the system's x-large, 1 its large, 2 ours, 3 the picture itself
    function thumb(picture, stage) {
        return url([systemThumb(picture.path, "x-large"), systemThumb(picture.path), ownThumb(picture), picture.path][stage]);
    }

    // The first stage that exists
    function firstStage(picture) {
        const key = Qt.md5(url(picture.path));
        if (systemLarger[key])
            return 0;
        if (systemThumbs[key])
            return 1;
        return ownThumbs[Qt.md5(picture.path + picture.mtime)] ? 2 : 3;
    }

    // Pictures nothing has a thumbnail for yet get one from vips, in the background
    function makeMissing() {
        if (thumbnailer.running)
            return;
        const pairs = [];
        for (const picture of pictures)
            if (firstStage(picture) === 3)
                pairs.push(picture.path, ownThumb(picture));
        if (pairs.length === 0)
            return;
        thumbnailer.command = ["sh", "-c", 'while [ $# -gt 1 ]; do vipsthumbnail "$1" -s 512 -o "$2[Q=88]" 2>/dev/null && echo "$2"; shift 2; done', "sh"].concat(pairs);
        thumbnailer.running = true;
    }

    // A little after startup, list the folder once so thumbnails and colours get ready
    Timer {
        running: true
        interval: 8000
        onTriggered: root.refresh()
    }

    Process {
        id: lister

        command: ["sh", "-c", `
            dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Wallpapers"
            mkdir -p "$1"
            echo "$dir"
            ls "$HOME/.cache/thumbnails/large" 2>/dev/null | sed -n 's/[.]png$//p' | tr '\n' ' '; echo
            ls "$HOME/.cache/thumbnails/x-large" 2>/dev/null | sed -n 's/[.]png$//p' | tr '\n' ' '; echo
            ls "$1" | sed -n 's/[.]jpg$//p' | tr '\n' ' '; echo
            find "$dir" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%T@\\t%p\\n' 2>/dev/null | sort -rn`, "sh", root.thumbs]
        stdout: StdioCollector {
            onStreamFinished: {
                const [folder, system, larger, own, ...lines] = text.split("\n");
                const set = line => {
                    const names = {};
                    for (const name of (line ?? "").split(" "))
                        if (name)
                            names[name] = true;
                    return names;
                };
                root.folder = folder ?? "";
                root.systemThumbs = set(system);
                root.systemLarger = set(larger);
                root.ownThumbs = set(own);
                root.pictures = lines.filter(line => line).map(line => {
                    const tab = line.indexOf("\t");
                    return { mtime: line.slice(0, tab), path: line.slice(tab + 1) };
                });
                root.listing = false;
                root.makeMissing();
                // Read every picture's colours in the background, so they're ready when wanted
                for (const picture of root.pictures)
                    Palettes.want(picture, false);
            }
        }
    }

    Process {
        id: thumbnailer

        stdout: SplitParser {
            onRead: line => {
                const name = line.trim().split("/").pop().replace(/[.]jpg$/, "");
                if (name)
                    root.ownThumbs[name] = true;
            }
        }
    }

    Process {
        id: browser

        property var answer: null
        property string title: ""

        command: ["sh", "-c", 'if command -v kdialog >/dev/null; then kdialog --title "$1" --getopenfilename "$2" "*.png *.jpg *.jpeg *.webp"; else zenity --file-selection --title "$1" --filename "$2/"; fi', "sh", title, root.folder || root.home]
        stdout: StdioCollector {
            onStreamFinished: {
                const answer = browser.answer;
                browser.answer = null;
                if (answer && text.trim())
                    answer(text.trim());
            }
        }
    }
}
