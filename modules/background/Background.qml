import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// One world per screen, all the way at the back, under the windows.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        screen: modelData
        color: Theme.skyTop
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "etea:background"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        World {
            anchors.fill: parent
            // Hyprland's slide moves the windows only, the world stays where it is
            angle: Config.pageTransition === "slide" ? 0 : Planet.resting
            interactive: true
        }
    }
}
