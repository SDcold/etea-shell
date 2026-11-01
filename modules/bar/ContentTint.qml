import QtQuick
import Quickshell
import qs.config

// Finds the colour of whatever a card is showing, so the whole card can take it on.
// Pictures give theirs up directly, anything else gets a tone of its own that never changes.
Item {
    id: root

    property string image: ""
    property string name: ""
    property string forced: "" // when the situation decides the colour instead

    visible: false

    function toneFor(text) {
        let total = 0;
        for (let i = 0; i < text.length; i++)
            total = (total * 31 + text.charCodeAt(i)) % 9973;
        return Theme.tones[total % Theme.tones.length];
    }

    // The liveliest colour in the picture, lifted so it glows on a dark sky
    readonly property color color: {
        if (forced)
            return forced;
        let best = null, score = 0.08;
        for (const color of quantizer.colors) {
            const here = color.hsvSaturation * color.hsvValue;
            if (here > score) {
                score = here;
                best = color;
            }
        }
        return best ? Qt.hsva(best.hsvHue, Math.min(best.hsvSaturation, 0.72), Math.max(best.hsvValue, 0.92), 1) : toneFor(name);
    }

    ColorQuantizer {
        id: quantizer

        source: root.image.startsWith("file:") ? root.image : ""
        depth: 3
        rescaleSize: 48
    }
}
