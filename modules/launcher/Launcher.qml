import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.services

// "Where do you want to go?" Your apps are a map of the sky: a constellation per kind of
// thing you do, your favourites burning brightest. Typing searches apps, open windows
// and sums, and ">" runs a command. A star can be carried to a page in the bar.
Scope {
    id: root

    GlobalShortcut {
        appid: "etea"
        name: "launcher"

        // Hyprland only reports a lone Super key once it's let go, as a release. It also
        // skips that release if another key came along, so Super + 1 leaves this alone.
        onReleased: Apps.open = !Apps.open
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

        // Where the constellations sit, and the shape each one draws
        readonly property var homes: [[0.17, 0.5], [0.39, 0.72], [0.6, 0.5], [0.8, 0.72]]
        readonly property var shape: [[0, 0], [100, -66], [186, 26], [66, 104], [-78, 84]]

        function refresh() {
            const stars = [], groups = [], wide = screen.width, tall = screen.height;
            if (mapping) {
                Apps.map().forEach((family, group) => {
                    const home = homes[group], first = stars.length;
                    family.stars.forEach((entry, rank) => stars.push(Object.assign({}, entry, {
                        x: wide * home[0] + shape[rank][0],
                        y: tall * home[1] + shape[rank][1],
                        rank: rank
                    })));
                    if (family.stars.length)
                        groups.push({ name: family.name, first: first, last: stars.length - 1, x: wide * home[0] + 60, y: tall * home[1] + 164 });
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
                if (results.length > 1)
                    groups.push({ name: "", first: 0, last: results.length - 1 });
            }
            found = stars;
            clusters = groups;
            chosen = 0;
            links.requestPaint();
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
            if (y > Theme.barGap + Theme.barHeight + 20)
                return 0;
            const page = Math.floor((x - Theme.barSide) / (Theme.pageWidth + Theme.pageGap)) + 1;
            return page >= 1 && page <= Config.pages ? page : 0;
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
                input.text = "";
                panel.refresh();
                input.forceActiveFocus();
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

            // The sky drifts gently against the pointer, so it feels deep
            transform: Translate {
                x: (panel.width / 2 - panel.pointer.x) * 0.018
                y: (panel.height / 2 - panel.pointer.y) * 0.018 + (1 - panel.shown) * 16
            }

            Canvas {
                id: links

                anchors.fill: parent
                renderStrategy: Canvas.Immediate
                onPaint: {
                    const g = getContext("2d");
                    g.reset();
                    g.strokeStyle = String(Theme.link);
                    g.globalAlpha = 0.32;
                    g.lineWidth = 1;
                    for (const group of panel.clusters) {
                        g.beginPath();
                        for (let i = group.first; i <= group.last; i++) {
                            const star = panel.found[i];
                            i === group.first ? g.moveTo(star.x, star.y) : g.lineTo(star.x, star.y);
                        }
                        g.stroke();
                    }
                }
            }

            Repeater {
                model: panel.clusters

                Text {
                    required property var modelData

                    visible: modelData.name !== ""
                    x: (modelData.x ?? 0) - width / 2
                    y: modelData.y ?? 0
                    text: modelData.name
                    color: Qt.alpha(Theme.text, 0.5)
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.letterSpacing: 1.5
                }
            }

            Repeater {
                model: panel.found

                Item {
                    id: node

                    required property var modelData
                    required property int index

                    readonly property bool chosen: index === panel.chosen
                    readonly property real reach: Math.hypot(panel.pointer.x - modelData.x, panel.pointer.y - modelData.y)
                    // Stars swell as the pointer gets close, your favourites are already bigger
                    readonly property real swell: 1 + 0.5 * Math.exp(-reach * reach / 14000)
                    readonly property real weight: modelData.rank === 0 ? 1.25 : modelData.rank === 1 ? 1 : 0.85
                    property bool carried: false

                    x: carried ? panel.pointer.x : modelData.x
                    y: carried ? panel.pointer.y : modelData.y
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
                            x: -width / 2
                            y: -height / 2
                            width: 44
                            height: 44
                            sourceSize: Qt.size(96, 96)
                            smooth: true
                            source: node.modelData.icon
                            opacity: node.chosen ? 1 : 0.8
                        }
                    }

                    Text {
                        visible: node.chosen
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 58
                        text: node.modelData.label
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 18
                        style: Text.Outline
                        styleColor: Qt.alpha("#000000", 0.35)
                    }

                    // Point to choose, click to open, carry it to a page of the bar to open it there
                    MouseArea {
                        x: -46
                        y: -46
                        width: 92
                        height: 92
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor
                        property point pressedAt: Qt.point(0, 0)

                        onEntered: panel.chosen = node.index
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

            Text {
                anchors.centerIn: input
                visible: input.text === ""
                text: "Où veux-tu aller ?"
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
                text: "Rien dans ce ciel."
                color: Qt.alpha(Theme.text, 0.6)
                font.family: Theme.font
                font.pixelSize: 20
            }
        }
    }
}
