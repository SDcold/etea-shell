pragma Singleton

import QtQuick
import Quickshell
import qs.config

// La Ceinture des ciels: choosing a picture is a short climb to where your air ends,
// with every picture hanging on a belt of small worlds around the planet.
// This holds what the belt is for and what's on it; the stage draws it.
Singleton {
    id: root

    // What the belt was opened for:
    //   role: "sky" (your sky), "world" (another world's sky), "newWorld", "lock", "photo"
    //   title, answer(path, from), from (where on screen it was asked from), planetId
    property var request: null
    readonly property bool open: request !== null
    readonly property string role: request?.role ?? ""

    // Everything on the belt, in order: the world's own sky first when it's a sky being
    // chosen, then the folder newest first, then a way out to another folder
    readonly property var items: {
        const list = [];
        if (role === "sky")
            list.push({ special: "world" });
        for (const picture of Pictures.pictures)
            list.push({ path: picture.path, mtime: picture.mtime, month: monthOf(picture.mtime) });
        list.push({ special: "elsewhere" });
        return list;
    }

    function monthOf(mtime) {
        const date = new Date(Number(mtime) * 1000);
        return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
    }

    // A picture of the focused stage, saved to a file, to check a step without looking
    signal grabWanted(string path)

    function ask(request) {
        if (open || Planet.phase !== Planet.Phase.Idle)
            return;
        root.request = request;
        Pictures.refresh();
        Planet.enterSkies();
    }

    function leave() {
        Planet.leaveSkies();
    }

    // Once the stage is back down, the request is over
    Connections {
        target: Planet

        function onPhaseChanged() {
            if (Planet.phase === Planet.Phase.Idle)
                root.request = null;
        }
    }
}
