import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.services

// "Where do you want to go?" Your apps are a map of the sky: every one of them, a
// constellation per kind of thing you do, your favourites burning brightest at its heart.
// The constellations float at different depths and drift against the pointer. Typing searches apps, open windows
// and sums, and ">" runs a command. A star can be carried to a page in the bar.
Scope {
    id: root

    GlobalShortcut {
        appid: "etea"
        name: "launcher"

        // Hyprland only reports a lone Super key once it's let go, as a release. It also
        // skips that release if another key came along, so Super + 1 leaves this alone.
        // Letting go of Super after moving or resizing a widget isn't a call for it either.
        onReleased: {
            if (Date.now() - Desk.lastGesture > 600)
                Apps.open = !Apps.open;
        }
    }

    // Straight to the emoji: the launcher opens with ":" already typed
    GlobalShortcut {
        appid: "etea"
        name: "emoji"
        onPressed: {
            Apps.startWith = ":";
            Apps.open = true;
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Apps.open = !Apps.open;
        }
    }

    PanelWindow {
        id: panel

        property real shown: Apps.open ? 1 : 0
        property var found: [] // every star on screen, each one knows its place
        property var clusters: []
        property int chosen: 0
        property point pointer: Qt.point(width / 2, height / 2)

        readonly property bool mapping: input.text.trim() === ""

        // Where the constellations sit, and how much room each has: four across the top, three
        // below with the biggest, the system, in the middle. Each one floats at its own depth.
        readonly property var homes: [[0.125, 0.47, 4], [0.375, 0.44, 4], [0.625, 0.47, 4], [0.875, 0.44, 4], [0.5, 0.8, 3], [0.167, 0.8, 3], [0.833, 0.8, 3]]
        readonly property var depths: [1, 0.7, 1.25, 0.85, 1.1, 0.8, 1.2]

        // Joined like a real constellation: each star to its nearest neighbour, no loops
        function tree(stars, first, last) {
            const joined = [first], lines = [], best = {};
            for (let i = first + 1; i <= last; i++)
                best[i] = { from: first, length: Math.hypot(stars[i].x - stars[first].x, stars[i].y - stars[first].y) };
            while (joined.length <= last - first) {
                let next = -1;
                for (const i in best) {
                    if (next < 0 || best[i].length < best[next].length)
                        next = Number(i);
                }
                lines.push([best[next].from, next]);
                joined.push(next);
                delete best[next];
                for (const i in best) {
                    const length = Math.hypot(stars[i].x - stars[next].x, stars[i].y - stars[next].y);
                    if (length < best[i].length)
                        best[i] = { from: next, length: length };
                }
            }
            return lines;
        }

        function refresh() {
            const stars = [], groups = [], wide = screen.width, tall = screen.height;
            if (mapping) {
                // A sunflower spiral per family: the most used at the heart, the rest winding out
                Apps.map().forEach((family, group) => {
                    if (!family.stars.length)
                        return;
                    const home = homes[group % homes.length], cx = wide * home[0], cy = tall * home[1];
                    // The spiral fills an ellipse of its slot: spaced so it all fits, never sparse
                    const rx = wide / home[2] / 2 * 0.82, ry = tall * 0.135, count = family.stars.length;
                    const step = Math.min(34, Math.sqrt(rx * ry / count));
                    const sx = Math.sqrt(rx / ry), sy = Math.sqrt(ry / rx);
                    const first = stars.length;
                    family.stars.forEach((entry, rank) => {
                        const angle = rank * 2.39996, reach = step * Math.sqrt(rank + (rank ? 0.6 : 0));
                        stars.push(Object.assign({}, entry, { x: cx + Math.cos(angle) * reach * sx, y: cy + Math.sin(angle) * reach * sy, rank: rank, fit: Math.min(1, step / 30) }));
                    });
                    const last = stars.length - 1;
                    groups.push({
                        name: family.name,
                        first: first,
                        last: last,
                        x: cx,
                        y: cy + step * Math.sqrt(count) * sy + 22,
                        depth: depths[group % depths.length],
                        lines: tree(stars, first, last)
                    });
                });
            } else {
                const results = Apps.search(input.text);
                results.forEach((entry, index) => {
                    const offset = index - (results.length - 1) / 2;
                    stars.push(Object.assign({}, entry, {
                        x: wide / 2 + offset * Theme.launcherSpacing,
                        y: tall * 0.56 + [0, 18, -12, 22, -8, 14, -16][index % 7],
                        rank: index === 0 ? 0 : 2
                    }));
                });
                if (results.length)
                    groups.push({ name: "", first: 0, last: results.length - 1, depth: 1, lines: results.slice(1).map((entry, index) => [index, index + 1]) });
            }
            found = stars;
            clusters = groups;
            chosen = 0;
        }

        function move(step) {
            if (found.length)
                chosen = (chosen + step + found.length) % found.length;
        }

        function launch() {
            if (found[chosen])
                Apps.run(found[chosen]);
        }

        // The page of the bar under the pointer, for dropping a star onto it
        function pageUnder(x, y) {
            const area = Planet.pagesArea;
            if (area.width === 0 || y < area.y - 20 || y > area.y + area.height + 20)
                return 0;
            const place = Math.floor((x - area.x) / (Theme.pageWidth + Theme.pageGap));
            return place >= 0 && place < Config.pages ? Planet.groupStart + place : 0;
        }

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: shown > 0.01
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "etea:launcher"
        WlrLayershell.keyboardFocus: Apps.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Behavior on shown {
            NumberAnimation { duration: Theme.launcherFade; easing.type: Easing.OutCubic }
        }

        Connections {
            target: Apps

            function onOpenChanged() {
                if (!Apps.open)
                    return;
                input.text = Apps.startWith;
                Apps.startWith = "";
                panel.refresh();
                input.forceActiveFocus();
            }
        }

        // Every app's icon, held in memory for good and loaded a few at a time after start:
        // the map shows them all, and fetching 150 icons when it opens left stars empty
        Item {
            visible: false

            ListModel {
                id: warm
            }

            Timer {
                running: warm.count < Apps.everything.length
                repeat: true
                interval: 60
                onTriggered: {
                    for (const app of Apps.everything.slice(warm.count, warm.count + 12))
                        warm.append({ icon: Quickshell.iconPath(app.icon, "application-x-executable") });
                }
            }

            Repeater {
                model: warm

                Image {
                    required property string icon

                    sourceSize: Qt.size(96, 96)
                    source: icon
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.launcherShade
            opacity: panel.shown * Theme.launcherDim

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPressed: Apps.open = false
                onPositionChanged: mouse => panel.pointer = Qt.point(mouse.x, mouse.y)
            }
        }

        Item {
            id: sky

            anchors.fill: parent
            opacity: panel.shown

            transform: Translate {
                y: (1 - panel.shown) * 16
            }

            // Far-off dust, barely moving with the pointer, so the constellations feel near.
            // Painted once each time the launcher opens.
            Canvas {
                id: dust

                anchors.fill: parent
                anchors.margins: -40
                renderStrategy: Canvas.Immediate

                transform: Translate {
                    x: (panel.width / 2 - panel.pointer.x) * 0.012
                    y: (panel.height / 2 - panel.pointer.y) * 0.012
                }

                Connections {
                    target: Apps

                    function onOpenChanged() {
                        if (Apps.open)
                            dust.requestPaint();
                    }
                }

                onPaint: {
                    const g = getContext("2d");
                    g.reset();
                    g.fillStyle = String(Theme.starAsleep);
                    for (let i = 0; i < 260; i++) {
                        g.globalAlpha = 0.08 + Math.random() * 0.3;
                        g.beginPath();
                        g.arc(Math.random() * width, Math.random() * height, 0.5 + Math.random() * 1.1, 0, Math.PI * 2);
                        g.fill();
                    }
                }
            }

            // One layer per constellation, each drifting against the pointer by its own depth
            Repeater {
                model: panel.clusters

                Item {
                    id: cluster

                    required property var modelData

                    readonly property real shiftX: (panel.width / 2 - panel.pointer.x) * 0.05 * modelData.depth
                    readonly property real shiftY: (panel.height / 2 - panel.pointer.y) * 0.05 * modelData.depth

                    anchors.fill: parent

                    transform: Translate {
                        x: cluster.shiftX
                        y: cluster.shiftY
                    }

                    // Only as big as the threads it holds, and drawn once: the layer moves, not the ink
                    Canvas {
                        id: links

                        readonly property var members: panel.found.slice(cluster.modelData.first, cluster.modelData.last + 1)
                        readonly property rect area: {
                            const xs = members.map(star => star.x), ys = members.map(star => star.y);
                            if (!xs.length)
                                return Qt.rect(0, 0, 1, 1);
                            const left = Math.min(...xs) - 2, top = Math.min(...ys) - 2;
                            return Qt.rect(left, top, Math.max(...xs) + 2 - left, Math.max(...ys) + 2 - top);
                        }

                        x: area.x
                        y: area.y
                        width: area.width
                        height: area.height
                        renderStrategy: Canvas.Immediate
                        onAreaChanged: requestPaint()
                        Component.onCompleted: requestPaint()
                        onPaint: {
                            const g = getContext("2d");
                            g.reset();
                            g.translate(-x, -y);
                            g.strokeStyle = String(Theme.link);
                            g.globalAlpha = 0.28;
                            g.lineWidth = 1;
                            g.beginPath();
                            for (const [a, b] of cluster.modelData.lines) {
                                g.moveTo(panel.found[a].x, panel.found[a].y);
                                g.lineTo(panel.found[b].x, panel.found[b].y);
                            }
                            g.stroke();
                        }
                    }

                    Text {
                        visible: cluster.modelData.name !== ""
                        x: (cluster.modelData.x ?? 0) - width / 2
                        y: cluster.modelData.y ?? 0
                        text: cluster.modelData.name
                        color: Qt.alpha(Theme.text, 0.5)
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.letterSpacing: 1.5
                    }

                    Repeater {
                        model: cluster.modelData.last - cluster.modelData.first + 1

                        Item {
                            id: node

                            required property int index
                            readonly property int number: cluster.modelData.first + index
                            readonly property var modelData: panel.found[number] ?? ({})

                            readonly property bool chosen: number === panel.chosen
                            readonly property real reach: Math.hypot(panel.pointer.x - cluster.shiftX - modelData.x, panel.pointer.y - cluster.shiftY - modelData.y)
                            // Stars swell as the pointer gets close. Your favourites sit at the heart,
                            // bigger; the rest get smaller as they wind out.
                            readonly property real swell: 1 + 0.5 * Math.exp(-reach * reach / 9000)
                            readonly property real weight: (modelData.rank === 0 ? 1.25 : modelData.rank < 5 ? 1 : Math.max(0.5, 0.8 - modelData.rank * 0.006)) * (modelData.fit ?? 1)
                            property bool carried: false

                            x: carried ? panel.pointer.x - cluster.shiftX : modelData.x
                            y: carried ? panel.pointer.y - cluster.shiftY : modelData.y
                            z: carried ? 5 : chosen ? 2 : 1

                            Behavior on x {
                                enabled: !node.carried
                                NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
                            }
                            Behavior on y {
                                enabled: !node.carried
                                NumberAnimation { duration: Theme.normal; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
                            }

                            Item {
                                scale: node.swell * node.weight * (node.chosen ? 1.2 : 1)

                                Behavior on scale {
                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                }

                                Star {
                                    x: -size
                                    y: -size
                                    size: 38
                                    lit: node.chosen
                                    animated: false
                                    opacity: node.chosen ? 0.85 : 0.22
                                }

                                Image {
                                    visible: !node.modelData.glyph
                                    x: -width / 2
                                    y: -height / 2
                                    width: 44
                                    height: 44
                                    sourceSize: Qt.size(96, 96)
                                    smooth: true
                                    source: node.modelData.icon ?? ""
                                    opacity: node.chosen ? 1 : 0.8
                                }

                                // An emoji is its own icon
                                Text {
                                    visible: !!node.modelData.glyph
                                    anchors.centerIn: parent
                                    text: node.modelData.glyph ?? ""
                                    font.pixelSize: 36
                                    opacity: node.chosen ? 1 : 0.8
                                }
                            }

                            Text {
                                visible: node.chosen
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 30 + 28 * node.weight
                                text: node.modelData.label ?? ""
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 18
                                style: Text.Outline
                                styleColor: Qt.alpha("#000000", 0.35)
                            }

                            // Point to choose, click to open, carry it to a page of the bar to open it there
                            MouseArea {
                                readonly property real hand: Math.max(36, 92 * node.weight)

                                x: -hand / 2
                                y: -hand / 2
                                width: hand
                                height: hand
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor
                                property point pressedAt: Qt.point(0, 0)

                                onEntered: panel.chosen = node.number
                                onPressed: mouse => pressedAt = Qt.point(mouse.x, mouse.y)
                                onPositionChanged: mouse => {
                                    const spot = mapToItem(null, mouse.x, mouse.y);
                                    panel.pointer = spot;
                                    if (pressed && node.modelData.kind === "app" && Math.hypot(mouse.x - pressedAt.x, mouse.y - pressedAt.y) > 10)
                                        node.carried = true;
                                }
                                onReleased: mouse => {
                                    const spot = mapToItem(null, mouse.x, mouse.y);
                                    if (!node.carried) {
                                        Apps.run(node.modelData);
                                    } else {
                                        node.carried = false;
                                        const page = panel.pageUnder(spot.x, spot.y);
                                        if (page)
                                            Apps.launch(node.modelData.app, page);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: input
                visible: input.text === ""
                text: Lang.t("Où veux-tu aller ?")
                color: Qt.alpha(Theme.text, 0.6)
                font: input.font
            }

            TextInput {
                id: input

                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.2
                width: parent.width * 0.7
                horizontalAlignment: TextInput.AlignHCenter
                color: Theme.text
                selectionColor: Theme.windowLit
                selectedTextColor: "#1c1208"
                cursorDelegate: Item {}
                font.family: Theme.font
                font.pixelSize: 40
                font.weight: Font.Light
                focus: true
                onTextChanged: panel.refresh()
                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        Apps.open = false;
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        panel.launch();
                        break;
                    case Qt.Key_Left:
                    case Qt.Key_Up:
                    case Qt.Key_Backtab:
                        panel.move(-1);
                        break;
                    case Qt.Key_Right:
                    case Qt.Key_Down:
                    case Qt.Key_Tab:
                        panel.move(1);
                        break;
                    default:
                        return;
                    }
                    event.accepted = true;
                }
            }

            // A line of light under the question, fading out at both ends
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: input.y + input.height + 14
                width: Math.min(parent.width * 0.5, 620) * panel.shown
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha(Theme.windowLit, 0) }
                    GradientStop { position: 0.5; color: Qt.alpha(Theme.windowLit, 0.8) }
                    GradientStop { position: 1; color: Qt.alpha(Theme.windowLit, 0) }
                }
            }

            Text {
                visible: input.text !== "" && panel.found.length === 0
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.54
                text: Lang.t("Rien dans ce ciel.")
                color: Qt.alpha(Theme.text, 0.6)
                font.family: Theme.font
                font.pixelSize: 20
            }
        }
    }
}
