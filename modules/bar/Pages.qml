import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// All six pages, side by side.
Row {
    id: root

    required property string monitorName

    spacing: 8

    Repeater {
        model: Config.pages

        PageConstellation {
            required property int index

            pageId: index + 1
            active: Hyprland.focusedWorkspace?.id === pageId
        }
    }
}
