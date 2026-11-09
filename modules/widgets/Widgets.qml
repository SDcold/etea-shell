import QtQuick
import Quickshell
import qs.config
import qs.modules.bar
import qs.services

// The widgets living in the sky. Which ones, where and how big is up to Desk.
// On the desktop they answer Super: drag one to move it, lined up by snap lines (Shift
// lets it go free), Super + wheel resizes the one under the pointer, and a right click
// opens its options. A right click on the empty sky
// offers the ones that aren't out yet.
Item {
    id: root

    property bool interactive: false
    readonly property bool skyStyle: Theme.widgetStyle === "sky"
    readonly property var files: skyStyle ? {
        clock: "GiantClock.qml",
        system: "SkySystem.qml",
        media: "SkyMedia.qml",
        weather: "SkyWeather.qml",
        calendar: "SkyCalendar.qml",
        tasks: "SkyTasks.qml",
        photo: "SkyPhoto.qml",
        lyrics: "SkyLyrics.qml"
    } : {
        clock: "ClockWidget.qml",
        system: "SystemWidget.qml",
        media: "MediaWidget.qml",
        weather: "WeatherWidget.qml",
        calendar: "CalendarWidget.qml",
        tasks: "TasksWidget.qml",
        photo: "PhotoWidget.qml",
        lyrics: "LyricsWidget.qml"
    }

    // A position moved just enough for the widget, scaled about its origin, to keep a
    // little room from the screen's edges
    function inside(position, length, origin, scale, room) {
        const margin = 12, left = position + origin * length * (1 - scale), right = left + length * scale;
        if (right - left > room - margin * 2)
            return position;
        return position + (left < margin ? margin - left : right > room - margin ? room - margin - right : 0);
    }

    // Snap lines: while a widget is carried, its edges and middle are pulled onto the
    // screen's middle and onto the edges and middles of the other widgets, and the lines
    // it lines up on are drawn, from one widget to the other
    readonly property real snapReach: 10
    property var guides: [] // { vertical, at, from, to }

    function snap(slot, x, y) {
        const others = [];
        for (let i = 0; i < slots.count; i++) {
            const other = slots.itemAt(i);
            if (other && other !== slot && other.width > 0)
                others.push(other.drawn(other.x, other.y));
        }
        const whole = { l: 0, t: 0, r: width, b: height };
        // The lines along one axis: the screen's middle, then each widget's three
        const linesOf = (lo, hi) => [{ at: (whole[lo] + whole[hi]) / 2, span: whole }].concat(...others.map(o => [o[lo], (o[lo] + o[hi]) / 2, o[hi]].map(at => ({ at: at, span: o }))));
        const pull = (lines, values) => {
            let shift = null;
            for (const line of lines)
                for (const value of values)
                    if (Math.abs(line.at - value) <= snapReach && (shift === null || Math.abs(line.at - value) < Math.abs(shift)))
                        shift = line.at - value;
            return shift ?? 0;
        };
        const valuesOf = (me, lo, hi) => [me[lo], (me[lo] + me[hi]) / 2, me[hi]];
        let me = slot.drawn(x, y);
        const across = linesOf("l", "r"), down = linesOf("t", "b");
        x += pull(across, valuesOf(me, "l", "r"));
        y += pull(down, valuesOf(me, "t", "b"));
        me = slot.drawn(x, y);
        // Every line it now sits on, each running across both widgets, a little past them
        const found = [];
        const note = (lines, values, vertical, lo, hi) => {
            for (const line of lines) {
                if (!values.some(value => Math.abs(line.at - value) < 0.5))
                    continue;
                const from = line.span === whole ? 0 : Math.min(me[lo], line.span[lo]) - 16;
                const to = line.span === whole ? (vertical ? height : width) : Math.max(me[hi], line.span[hi]) + 16;
                const same = found.find(guide => guide.vertical === vertical && Math.abs(guide.at - line.at) < 0.5);
                if (same) {
                    same.from = Math.min(same.from, from);
                    same.to = Math.max(same.to, to);
                } else {
                    found.push({ vertical: vertical, at: line.at, from: from, to: to });
                }
            }
        };
        note(across, valuesOf(me, "l", "r"), true, "t", "b");
        note(down, valuesOf(me, "t", "b"), false, "l", "r");
        guides = found;
        return Qt.point(x, y);
    }

    function origin(ax, ay) {
        return [[Item.TopLeft, Item.Top, Item.TopRight], [Item.Left, Item.Center, Item.Right], [Item.BottomLeft, Item.Bottom, Item.BottomRight]][Math.round(ay * 2)][Math.round(ax * 2)];
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.RightButton
        onPressed: mouse => Desk.openMenu("add", Qt.point(mouse.x, mouse.y), QsWindow.window?.screen ?? null)
    }

    Repeater {
        id: slots

        model: Desk.shown

        Item {
            id: slot

            required property string modelData
            readonly property string type: modelData
            readonly property var place: Desk.place(type)
            readonly property real size: Desk.size(type)

            property bool dragging: false
            property point dragAt
            property point grabbedAt
            property point startedAt

            // Where the widget sits: its saved spot, or under your hand while you carry it.
            // Wherever the spot is, the widget as drawn stays on the screen.
            x: dragging ? dragAt.x : root.inside(place.x * root.width - width * place.ax, width, Math.round(place.ax * 2) / 2, scale, root.width)
            y: dragging ? dragAt.y : root.inside(place.y * root.height - height * place.ay, height, Math.round(place.ay * 2) / 2, scale, root.height)
            width: content.width
            height: content.height
            // Sky widgets are drawn from the screen's height, so they grow crisp. The
            // celestial ones are fixed cards and get scaled around the point they stand on.
            scale: root.skyStyle ? 1 : size
            transformOrigin: root.origin(place.ax, place.ay)

            // The widget as it's drawn at a spot, scaled about its origin
            function drawn(atX, atY) {
                const left = atX + Math.round(place.ax * 2) / 2 * width * (1 - scale);
                const top = atY + Math.round(place.ay * 2) / 2 * height * (1 - scale);
                return { l: left, t: top, r: left + width * scale, b: top + height * scale };
            }

            onSizeChanged: {
                if (root.interactive)
                    resized.restart();
            }

            Loader {
                id: content

                source: root.files[slot.type] ?? ""
                onLoaded: {
                    if ("sky" in item)
                        item.sky = Qt.binding(() => root.height * slot.size);
                    if ("options" in item)
                        item.options = Qt.binding(() => Desk.entry(slot.type));
                }
            }

            // Shows the widget can be handled: while Super is down over it, while carried,
            // and for a moment after a resize
            Item {
                anchors.fill: parent
                anchors.margins: -14
                opacity: slot.dragging || resized.running || (!Desk.frozen && hover.hovered && (hover.point.modifiers & Qt.MetaModifier)) ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.fast }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: Qt.alpha(Desk.ink, 0.04)
                    border.width: 1
                    border.color: Qt.alpha(Desk.ink, 0.32)
                }

                Repeater {
                    model: [[0, 0], [1, 0], [1, 1], [0, 1]]

                    Star {
                        required property var modelData

                        x: modelData[0] * parent.width - size
                        y: modelData[1] * parent.height - size
                        size: 6
                        lit: true
                        animated: false
                    }
                }
            }

            Timer {
                id: resized

                interval: 700
            }

            HoverHandler {
                id: hover

                enabled: root.interactive
                onHoveredChanged: {
                    if (hovered)
                        Desk.hovered = slot.type;
                    else if (Desk.hovered === slot.type)
                        Desk.hovered = "";
                }
            }

            // Plain clicks go through to the widget's own buttons, only Super and the
            // right button stop here
            MouseArea {
                anchors.fill: parent
                enabled: root.interactive
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: slot.dragging ? Qt.ClosedHandCursor : Qt.ArrowCursor
                onPressed: mouse => {
                    const at = mapToItem(root, mouse.x, mouse.y);
                    if (mouse.button === Qt.RightButton) {
                        Desk.openMenu(slot.type, at, QsWindow.window?.screen ?? null);
                        return;
                    }
                    // Frozen widgets only let the click through
                    if (Desk.frozen || (!Desk.takeGrab() && !(mouse.modifiers & Qt.MetaModifier))) {
                        mouse.accepted = false;
                        return;
                    }
                    Desk.lastGesture = Date.now();
                    slot.grabbedAt = at;
                    slot.startedAt = Qt.point(slot.x, slot.y);
                    slot.dragAt = slot.startedAt;
                    slot.dragging = true;
                    Desk.carrying = true;
                }
                onPositionChanged: mouse => {
                    if (!slot.dragging)
                        return;
                    const at = mapToItem(root, mouse.x, mouse.y);
                    const x = slot.startedAt.x + at.x - slot.grabbedAt.x;
                    const y = slot.startedAt.y + at.y - slot.grabbedAt.y;
                    if (mouse.modifiers & Qt.ShiftModifier) {
                        root.guides = [];
                        slot.dragAt = Qt.point(x, y);
                    } else {
                        slot.dragAt = root.snap(slot, x, y);
                    }
                }
                onReleased: {
                    if (!slot.dragging)
                        return;
                    Desk.lastGesture = Date.now();
                    Desk.move(slot.type, (slot.dragAt.x + slot.width * slot.place.ax) / root.width, (slot.dragAt.y + slot.height * slot.place.ay) / root.height);
                    slot.dragging = false;
                    Desk.carrying = false;
                    root.guides = [];
                }
                onCanceled: {
                    slot.dragging = false;
                    Desk.carrying = false;
                    root.guides = [];
                }
            }
        }
    }

    // The snap lines, a thin line of ink with a star at each end
    Repeater {
        model: root.guides

        Item {
            id: guide

            required property var modelData
            readonly property real at: Math.round(modelData.at)

            x: modelData.vertical ? at : modelData.from
            y: modelData.vertical ? modelData.from : at
            width: modelData.vertical ? 1 : modelData.to - modelData.from
            height: modelData.vertical ? modelData.to - modelData.from : 1

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Desk.ink, 0.45)
            }

            Repeater {
                model: [0, 1]

                Star {
                    required property var modelData

                    x: (guide.modelData.vertical ? 0.5 : modelData * guide.width) - size
                    y: (guide.modelData.vertical ? modelData * guide.height : 0.5) - size
                    size: 4
                    lit: true
                    animated: false
                    halo: false
                    fill: Desk.ink
                }
            }
        }
    }
}
