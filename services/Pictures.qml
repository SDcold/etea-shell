pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Picking a picture: the wallpapers in your Pictures folder, as a wall of thumbnails.
// Thumbnails come from the system's cache when another app already made them, then from
// ours, and only then from the picture itself, which we keep small for next time.
Singleton {
    id: root

    property bool open: false
    property string title: ""
    property var answer: null // what to do with the picture once picked
    property var extra: null // { label, act }: one more way out, beside the pictures
    property string folder: ""
    property var pictures: [] // { path, mtime }, newest first
    property bool listing: false
    // Which thumbnails already exist, so none is asked for in vain
    property var systemThumbs: ({})
    property var ownThumbs: ({})

    readonly property string home: Quickshell.env("HOME")
    readonly property string thumbs: `${Quickshell.env("XDG_CACHE_HOME") || home + "/.cache"}/etea/thumbs`

    function pick(title, answer, extra) {
        root.title = title;
        root.answer = answer;
        root.extra = extra ?? null;
        open = true;
        refresh();
    }

    function refresh() {
        listing = true;
        lister.running = true;
    }

    function choose(path) {
        const answer = root.answer;
        close();
        if (answer && path)
            answer(path);
    }

    function close() {
        open = false;
        answer = null;
        extra = null;
    }

    function takeExtra() {
        const act = extra?.act;
        close();
        if (act)
            act();
    }

    // Somewhere else: the system's own picker, once ours is out of its way
    function browse() {
        browser.answer = answer;
        open = false;
        browser.running = true;
    }

    function url(path) {
        return "file://" + encodeURI(path).replace(/#/g, "%23").replace(/\?/g, "%3F");
    }

    // Where a picture's thumbnail would be: the shared cache other apps fill, then ours
    function systemThumb(path) {
        return `${home}/.cache/thumbnails/large/${Qt.md5(url(path))}.png`;
    }

    function ownThumb(picture) {
        return `${thumbs}/${Qt.md5(picture.path + picture.mtime)}.jpg`;
    }

    // The quickest source there is: 0 the system's thumbnail, 1 ours, 2 the picture itself
    function firstStage(picture) {
        if (systemThumbs[Qt.md5(url(picture.path))])
            return 0;
        return ownThumbs[Qt.md5(picture.path + picture.mtime)] ? 1 : 2;
    }

    Process {
        id: lister

        command: ["sh", "-c", `
            dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Wallpapers"
            mkdir -p "$1"
            echo "$dir"
            ls "$HOME/.cache/thumbnails/large" 2>/dev/null | sed -n 's/[.]png$//p' | tr '\n' ' '; echo
            ls "$1" | sed -n 's/[.]jpg$//p' | tr '\n' ' '; echo
            find "$dir" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%T@\\t%p\\n' 2>/dev/null | sort -rn`, "sh", root.thumbs]
        stdout: StdioCollector {
            onStreamFinished: {
                const [folder, system, own, ...lines] = text.split("\n");
                const set = line => {
                    const names = {};
                    for (const name of (line ?? "").split(" "))
                        if (name)
                            names[name] = true;
                    return names;
                };
                root.folder = folder ?? "";
                root.systemThumbs = set(system);
                root.ownThumbs = set(own);
                root.pictures = lines.filter(line => line).map(line => {
                    const tab = line.indexOf("\t");
                    return { mtime: line.slice(0, tab), path: line.slice(tab + 1) };
                });
                root.listing = false;
            }
        }
    }

    Process {
        id: browser

        property var answer: null

        command: ["sh", "-c", 'if command -v kdialog >/dev/null; then kdialog --title "$1" --getopenfilename "$2" "*.png *.jpg *.jpeg *.webp"; else zenity --file-selection --title "$1" --filename "$2/"; fi', "sh", root.title, root.folder || root.home]
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
