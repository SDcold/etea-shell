import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.services

// "Where do you want to go?" The sky dims, the question appears, and your apps
// light up as a constellation. Typing narrows it down to the star you're after.
Scope {
    id: root

    GlobalShortcut {
        appid: "etea"
        name: "launcher"
        onPressed: Apps.open = !Apps.open
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
        property var found: []
        property int chosen: 0

        function refresh() {
            found = Apps.search(input.text);
            chosen = 0;
            links.requestPaint();
        }

        function move(step) {
            if (found.length)
                chosen = (chosen + step + found.length) % found.length;
        }

        function launch() {
            if (found[chosen])
                Apps.launch(found[chosen]);
        }

        // The constellation sweeps gently upward through the middle, no star sits quite in line
        function point(index) {
            const count = found.length, spread = Theme.launcherSpacing;
            const offset = index - (count - 1) / 2;
            const wander = [0, 22, -14, 26, -8, 18, -20][index % 7];
            return Qt.point(width / 2 + offset * spread, height * 0.56 - Math.abs(offset) * -10 + wander);
        }

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: shown > 0.01
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "etea:launcher"
        WlrLayershell.keyboardFocus: Apps.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Behavior on shown {
            NumberAnimation {
                duration: Theme.launcherFade
                easing.type: Easing.OutCubic
            }
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
                onPressed: Apps.open = false
            }
        }

        Item {
            anchors.fill: parent
            opacity: panel.shown
            transform: Translate {
                y: (1 - panel.shown) * 16
            }

            Text {
                anchors.centerIn: input
                visible: input.text === ""
                text: "Où veux-tu aller ?"
                color: Qt.alpha(Theme.text, 0.55)
                font: input.font
            }

            TextInput {
                id: input

                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.3
                width: parent.width * 0.7
                horizontalAlignment: TextInput.AlignHCenter
                color: Theme.text
                selectionColor: Theme.windowLit
                selectedTextColor: "#1c1208"
                cursorDelegate: Item {}
                font.family: Theme.font
                font.pixelSize: 46
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
                y: input.y + input.height + 16
                width: Math.min(parent.width * 0.5, 620) * panel.shown
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha(Theme.windowLit, 0) }
                    GradientStop { position: 0.5; color: Qt.alpha(Theme.windowLit, 0.8) }
                    GradientStop { position: 1; color: Qt.alpha(Theme.windowLit, 0) }
                }
            }

            // The thread between the stars, same as in the bar
            Canvas {
                id: links

                anchors.fill: parent
                renderStrategy: Canvas.Immediate
                onWidthChanged: requestPaint()
                onPaint: {
                    const g = getContext("2d");
                    g.reset();
                    if (panel.found.length < 2)
                        return;
                    g.strokeStyle = String(Theme.link);
                    g.globalAlpha = 0.34;
                    g.lineWidth = 1;
                    g.beginPath();
                    panel.found.forEach((app, i) => {
                        const p = panel.point(i);
                        i ? g.lineTo(p.x, p.y) : g.moveTo(p.x, p.y);
                    });
                    g.stroke();
                }
            }

            Repeater {
                model: panel.found

                Item {
                    id: node

                    required property var modelData
                    required property int index

                    readonly property bool chosen: index === panel.chosen
                    readonly property point spot: panel.point(index)

                    x: spot.x
                    y: spot.y

                    Behavior on x {
                        NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic }
                    }
                    Behavior on y {
                        NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic }
                    }

                    Star {
                        x: -size
                        y: -size
                        size: node.chosen ? 46 : 26
                        lit: node.chosen
                        animated: false
                        opacity: node.chosen ? 0.9 : 0.35

                        Behavior on size {
                            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                        }
                    }

                    Image {
                        x: -width / 2
                        y: -height / 2
                        width: node.chosen ? 58 : 42
                        height: width
                        sourceSize: Qt.size(116, 116)
                        smooth: true
                        source: Quickshell.iconPath(node.modelData.icon, "application-x-executable")
                        opacity: node.chosen ? 1 : 0.75

                        Behavior on width {
                            NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        visible: node.chosen
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 66
                        text: node.modelData.name
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 21
                    }

                    MouseArea {
                        x: -46
                        y: -46
                        width: 92
                        height: 92
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: panel.chosen = node.index
                        onPressed: Apps.launch(node.modelData)
                    }
                }
            }

            Text {
                visible: input.text !== "" && panel.found.length === 0
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.54
                text: "Rien dans ce ciel."
                color: Qt.alpha(Theme.text, 0.6)
                font.family: Theme.font
                font.pixelSize: 19
            }
        }
    }
}
