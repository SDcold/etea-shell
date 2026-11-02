import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

// All six pages, side by side.
Row {
    id: root

    required property string monitorName
    property real windowY: 0 // where the bar's surface starts on screen

    // Tell the shell where the pages are, so stars can fly to them and apps be dropped on them
    function publish() {
        if (monitorName !== (Hyprland.focusedMonitor?.name ?? monitorName))
            return;
        const at = mapToItem(null, 0, 0);
        Planet.pagesArea = Qt.rect(at.x, at.y + windowY, width, height);
    }

    spacing: Theme.pageGap

    onXChanged: Qt.callLater(publish)
    onWidthChanged: Qt.callLater(publish)
    onWindowYChanged: Qt.callLater(publish)
    Component.onCompleted: Qt.callLater(publish)
    Component.onDestruction: {
        if (monitorName === (Hyprland.focusedMonitor?.name ?? monitorName))
            Planet.pagesArea = Qt.rect(0, 0, 0, 0);
    }

    Connections {
        target: root.parent

        function onXChanged() {
            Qt.callLater(root.publish);
        }
    }

    Connections {
        target: root.parent?.parent ?? null

        function onXChanged() {
            Qt.callLater(root.publish);
        }

        function onYChanged() {
            Qt.callLater(root.publish);
        }
    }

    Connections {
        target: Hyprland

        function onFocusedMonitorChanged() {
            Qt.callLater(root.publish);
        }
    }

    Repeater {
        model: Config.pages

        PageConstellation {
            required property int index

            pageId: index + 1
            active: Hyprland.focusedWorkspace?.id === pageId
        }
    }
}
