import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.modules.bar
import qs.services

// Opening a window is a star being born. Hyprland keeps the real window invisible
// for a moment (see Illumination), and we open a live copy of it through a growing star.
Item {
    id: root

    required property real screenX
    required property real screenY
    property bool active: true

    property var window: null
    property string waitingFor: ""
    property int tries: 0
    property bool playing: false

    // A new window often gets resized while it settles in, so this follows it live
    readonly property rect area: {
        const info = window?.lastIpcObject;
        if (!info?.size)
            return Qt.rect(0, 0, 0, 0);
        const edge = Theme.traceWidth;
        return Qt.rect(info.at[0] - screenX - edge, info.at[1] - screenY - edge, info.size[0] + edge * 2, info.size[1] + edge * 2);
    }

    function look() {
        const found = Hyprland.toplevels.values.find(t => t.address === waitingFor || t.address === `0x${waitingFor}`);
        const info = found?.lastIpcObject;
        if (!info?.size || info.size[0] <= 0) {
            if (++tries < 12) {
                Hyprland.refreshToplevels();
                searching.restart();
            }
            return;
        }
        if (found.workspace?.id === Planet.current && info.fullscreen !== 2)
            start(found);
    }

    function start(found) {
        window = found;
        Planet.birthing = found.address;
        mask.reach = 0;
        scene.opacity = 1;
        playing = true;
        birth.restart();
    }

    function finish() {
        playing = false;
        window = null;
        Planet.birthing = "";
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "openwindow" || !root.active || root.playing)
                return;
            root.waitingFor = event.data.split(",")[0];
            root.tries = 0;
            Hyprland.refreshToplevels();
            searching.restart();
        }
    }

    Timer {
        running: root.playing
        repeat: true
        interval: 32
        onTriggered: Hyprland.refreshToplevels()
    }

    Timer {
        id: searching

        interval: 25
        onTriggered: root.look()
    }

    Item {
        id: scene

        anchors.fill: parent
        visible: root.playing

        Item {
            id: copy

            x: root.area.x
            y: root.area.y
            width: root.area.width
            height: root.area.height
            opacity: 0
            layer.enabled: true

            ClippingRectangle {
                anchors.fill: parent
                radius: Theme.windowRadius + Theme.traceWidth
                color: "transparent"

                ScreencopyView {
                    anchors.fill: parent
                    anchors.margins: Theme.traceWidth
                    captureSource: root.window?.wayland ?? null
                    live: true
                }
            }
        }

        StarMask {
            id: mask

            x: root.area.x
            y: root.area.y
            width: root.area.width
            height: root.area.height
            source: copy
        }

        Star {
            id: star

            x: root.area.x + root.area.width / 2 - width / 2
            y: root.area.y + root.area.height / 2 - height / 2
            size: Theme.closeStarSize
            lit: true
            appear: root.playing
        }
    }

    SequentialAnimation {
        id: birth

        PropertyAction {
            target: mask
            property: "shine"
            value: 0.9
        }

        // The star flares up first, then opens onto the window
        PauseAnimation { duration: Theme.openSpark }

        ParallelAnimation {
            NumberAnimation {
                target: mask
                property: "reach"
                to: mask.fullReach
                duration: Theme.openReveal
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: mask
                property: "shine"
                to: 0
                duration: Theme.openReveal
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: star
                property: "opacity"
                from: 1
                to: 0
                duration: Theme.openReveal * 0.6
            }
        }

        // Hyprland's fade only really starts at the very end, so let go right as it does.
        // Fading together keeps a see-through window from doubling up with its copy.
        PauseAnimation { duration: Math.max(0, Theme.openHold - Theme.openSpark - Theme.openReveal) }

        NumberAnimation {
            target: scene
            property: "opacity"
            to: 0
            duration: 130
        }

        ScriptAction {
            script: {
                star.opacity = 1;
                root.finish();
            }
        }
    }
}
