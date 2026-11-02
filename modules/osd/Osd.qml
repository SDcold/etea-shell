import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.modules.bar.menus

// A small porthole that answers the volume and brightness keys. Its horizon
// climbs with the level, so you can read it without reading it.
Scope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    property string kind: "volume"
    property real brightness: -1
    property real maxBrightness: 1
    property bool awake: false
    property bool showing: false

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real level: kind === "volume" ? (muted ? 0 : Math.min(1, volume)) : Math.max(0, brightness)
    readonly property string icon: kind === "brightness" ? "brightness" : muted ? "speaker-x" : volume > 0.5 ? "speaker-high" : "speaker-low"

    function show(what) {
        if (!awake)
            return;
        kind = what;
        showing = true;
        hide.restart();
    }

    onVolumeChanged: show("volume")
    onMutedChanged: show("volume")

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // Nothing to announce while everything is still starting up
    Timer {
        running: true
        interval: 1500
        onTriggered: root.awake = true
    }

    Timer {
        id: hide

        interval: 1400
        onTriggered: root.showing = false
    }

    // The screen doesn't announce its brightness, so we peek at it a few times a second
    Process {
        id: reader

        command: ["sh", "-c", "cat /sys/class/backlight/*/brightness /sys/class/backlight/*/max_brightness 2>/dev/null | head -2"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [now, most] = text.trim().split("\n").map(Number);
                if (!most)
                    return;
                const value = now / most;
                if (root.brightness >= 0 && Math.abs(value - root.brightness) > 0.001) {
                    root.brightness = value;
                    root.show("brightness");
                } else {
                    root.brightness = value;
                }
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 400
        onTriggered: reader.running = true
    }

    PanelWindow {
        id: panel

        property real shown: root.showing ? 1 : 0

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: shown > 0.01
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 340
        implicitHeight: 104
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "etea:osd"
        margins.bottom: 54 + (Theme.barOnTop ? 0 : Theme.barReserve)

        anchors {
            bottom: true
        }

        mask: Region {}

        Behavior on shown {
            NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
        }

        Item {
            x: 10
            y: 12 + (1 - panel.shown) * 40
            width: 320
            height: 80
            opacity: Math.min(1, panel.shown)

            HandCard {
                anchors.fill: parent
                seed: root.kind
                tint: root.kind === "volume" ? "#e98fb0" : "#ffd08a"
                rise: 0.05 + root.level * 0.22
                alive: panel.visible
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 14

                Icon {
                    name: root.icon
                    size: 26
                }

                MenuSlider {
                    Layout.fillWidth: true
                    tint: Theme.text
                    value: root.level
                }

                Text {
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                    text: Math.round((root.kind === "volume" ? root.volume : root.level) * 100)
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }
            }
        }
    }
}
