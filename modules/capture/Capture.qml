import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.modules.bar

// Take a piece of the screen. Everything freezes, you draw a zone with stars on its
// corners, and the capture lands in your pictures and on your clipboard.
Scope {
    id: root

    property bool open: false
    property point start: Qt.point(0, 0)
    property point end: Qt.point(0, 0)
    property bool dragging: false

    readonly property rect zone: Qt.rect(Math.min(start.x, end.x), Math.min(start.y, end.y), Math.abs(end.x - start.x), Math.abs(end.y - start.y))

    function take() {
        const screen = panel.screen, z = zone;
        const geometry = `${Math.round(screen.x + z.x)},${Math.round(screen.y + z.y)} ${Math.round(z.width)}x${Math.round(z.height)}`;
        open = false;
        saver.command = ["sh", "-c", `dir="$(xdg-user-dir PICTURES)/Captures"; mkdir -p "$dir"; file="$dir/etea-$(date +%Y%m%d-%H%M%S).png"; grim -g "$1" "$file" && wl-copy < "$file" && notify-send -a Capture -i "$file" "Capture enregistrée" "$file"`, "sh", geometry];
        settle.restart();
    }

    onOpenChanged: {
        dragging = false;
        start = Qt.point(0, 0);
        end = Qt.point(0, 0);
    }

    GlobalShortcut {
        appid: "etea"
        name: "capture"
        onPressed: root.open = !root.open
    }

    IpcHandler {
        target: "capture"

        function toggle(): void {
            root.open = !root.open;
        }
    }

    // Let the overlay leave the screen before taking the picture
    Timer {
        id: settle

        interval: 120
        onTriggered: saver.running = true
    }

    Process {
        id: saver
    }

    PanelWindow {
        id: panel

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: root.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "etea:capture"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Loader {
            anchors.fill: parent
            active: root.open

            sourceComponent: ScreencopyView {
                captureSource: panel.screen
                live: false
            }
        }

        // The dimmed screen, with the chosen zone left clear
        Item {
            anchors.fill: parent

            Rectangle { x: 0; y: 0; width: parent.width; height: root.zone.y; color: "#8c05060e" }
            Rectangle { x: 0; y: root.zone.y + root.zone.height; width: parent.width; height: parent.height - y; color: "#8c05060e" }
            Rectangle { x: 0; y: root.zone.y; width: root.zone.x; height: root.zone.height; color: "#8c05060e" }
            Rectangle { x: root.zone.x + root.zone.width; y: root.zone.y; width: parent.width - x; height: root.zone.height; color: "#8c05060e" }
        }

        Rectangle {
            visible: root.zone.width > 0
            x: root.zone.x
            y: root.zone.y
            width: root.zone.width
            height: root.zone.height
            color: "transparent"
            border.width: 1
            border.color: Theme.windowLit
        }

        Repeater {
            model: [[0, 0], [1, 0], [1, 1], [0, 1]]

            Star {
                required property var modelData

                visible: root.zone.width > 0
                x: root.zone.x + root.zone.width * modelData[0] - size
                y: root.zone.y + root.zone.height * modelData[1] - size
                size: 9
                lit: true
                animated: false
            }
        }

        Text {
            visible: root.zone.width > 0
            x: root.zone.x
            y: Math.max(8, root.zone.y - 30)
            text: `${Math.round(root.zone.width)} × ${Math.round(root.zone.height)}`
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 13
        }

        Text {
            visible: !root.dragging && root.zone.width === 0
            anchors.centerIn: parent
            text: "Trace la zone à capturer"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 24
            font.weight: Font.Light
        }

        MouseArea {
            anchors.fill: parent
            focus: true
            cursorShape: Qt.CrossCursor
            onPressed: mouse => {
                root.start = Qt.point(mouse.x, mouse.y);
                root.end = root.start;
                root.dragging = true;
            }
            onPositionChanged: mouse => root.end = Qt.point(mouse.x, mouse.y)
            onReleased: {
                root.dragging = false;
                if (root.zone.width > 4 && root.zone.height > 4)
                    root.take();
            }
            Keys.onEscapePressed: root.open = false
        }
    }
}
