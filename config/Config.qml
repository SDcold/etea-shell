pragma Singleton

import QtQuick
import Quickshell

// What people can tweak. Until we have a settings page, it happens here.
Singleton {
    readonly property int pages: 6
    readonly property var status: ["notifications", "network", "bluetooth", "volume", "battery"]
    readonly property string locale: "fr_FR"
    readonly property int launcherStars: 7 // how many apps the launcher shows at once
    readonly property string groundMusic: "lines" // on empty pages: "lines", "bars" or "off"

    // Widgets in the sky, for when a page is empty. x and y are shares of the screen.
    // There's a clock, a system and a media one. Move them or leave any out.
    readonly property var widgets: [
        { type: "clock", x: 0.5, y: 0.34 },
        { type: "system", x: 0.14, y: 0.3 },
        { type: "media", x: 0.84, y: 0.3 }
    ]

    // Decorate the sky: drop a PNG or SVG in decorations/ and describe it here.
    // x, y and width are shares of the screen, opacity and rotation are optional.
    // Example: { file: "comete.svg", x: 0.2, y: 0.3, width: 0.1, opacity: 0.8, rotation: -12 }
    readonly property var decorations: []
}
