import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.modules.bar
import qs.services

// Opening a window is a star being born. The new window is still invisible when we
// hear about it, so we photograph the screen as it is and lay that piece over the spot.
// A star then opens a hole in the photo, onto the real window. Nothing ever has to swap
// places, and whatever was already there stays put until the star reaches it.
Item {
    id: root

    required property var output
    required property real screenX
    required property real screenY
    property bool active: true

    property var window: null
    property string waitingFor: ""
    property int tries: 0
    property bool playing: false
    property bool photoReady: false

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
        if (found.workspace?.id !== Planet.current || info.fullscreen === 2) {
            photo.active = false;
            return;
        }
        window = found;
        if (photoReady)
            start();
    }

    function start() {
        Planet.birthing = window.address;
        mask.reach = 0;
        mask.shine = 0.9;
        star.opacity = 1;
        playing = true;
        birth.restart();
    }

    function finish() {
        playing = false;
        window = null;
        photoReady = false;
        photo.active = false;
        Planet.birthing = "";
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "openwindow" || !root.active || root.playing)
                return;
            root.waitingFor = event.data.split(",")[0];
            root.tries = 0;
            root.photoReady = false;
            photo.active = true;
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
        anchors.fill: parent
        opacity: 0

        Loader {
            id: photo

            anchors.fill: parent
            active: false

            sourceComponent: ScreencopyView {
                captureSource: root.output
                live: false
                onHasContentChanged: {
                    if (!hasContent)
                        return;
                    root.photoReady = true;
                    if (root.window && !root.playing)
                        root.start();
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.playing

        ShaderEffectSource {
            id: patch

            sourceItem: photo.item
            sourceRect: root.area
            live: false
            visible: false
            width: root.area.width
            height: root.area.height
        }

        StarMask {
            id: mask

            x: root.area.x
            y: root.area.y
            width: root.area.width
            height: root.area.height
            source: patch
            flipped: 1
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
                to: 0
                duration: Theme.openReveal * 0.6
            }
        }

        ScriptAction {
            script: root.finish()
        }
    }
}
