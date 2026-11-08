import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

// The wall of pictures a setting opens when it wants an image. It sits above everything,
// Settings included, on a dimmed sky.
PanelWindow {
    id: panel

    property real shown: Pictures.open ? 1 : 0

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: shown > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "etea:pictures"
    WlrLayershell.keyboardFocus: Pictures.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
        target: Pictures

        function onOpenChanged() {
            if (Pictures.open)
                card.begin();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.launcherShade
        opacity: panel.shown * Theme.launcherDim

        MouseArea {
            anchors.fill: parent
            onPressed: Pictures.close()
        }
    }

    PictureWall {
        id: card

        anchors.centerIn: parent
        width: Math.min(1180, panel.width - 120)
        height: Math.min(820, panel.height - 120)
        opacity: panel.shown
        scale: 0.97 + 0.03 * panel.shown
    }
}
