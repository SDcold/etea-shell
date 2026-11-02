import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

// The pages of the group you're in, side by side. Moving to another group tips them
// over one after the other, and the next ones come up in their place.
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

        Item {
            id: cell

            required property int index
            property int page: Planet.groupStart + index
            property real tilt: 0
            property int direction: 1

            implicitWidth: Theme.pageWidth
            implicitHeight: Theme.barHeight

            PageConstellation {
                pageId: cell.page
                active: Hyprland.focusedWorkspace?.id === pageId
                opacity: 1 - Math.abs(cell.tilt) / 90 * 0.8
                transform: Rotation {
                    origin.x: Theme.pageWidth / 2
                    origin.y: Theme.barHeight / 2
                    axis { x: 1; y: 0; z: 0 }
                    angle: cell.tilt
                }
            }

            Connections {
                target: Planet

                function onGroupStartChanged() {
                    if (Planet.groupStart + cell.index === cell.page)
                        return;
                    cell.direction = Planet.groupStart > cell.page ? 1 : -1;
                    flip.restart();
                }
            }

            // The page tips away, changes, and swings back up, a beat after its neighbour
            SequentialAnimation {
                id: flip

                PauseAnimation { duration: cell.index * 28 }
                NumberAnimation { target: cell; property: "tilt"; to: 90 * cell.direction; duration: 130; easing.type: Easing.InCubic }
                ScriptAction { script: cell.page = Planet.groupStart + cell.index }
                PropertyAction { target: cell; property: "tilt"; value: -90 * cell.direction }
                NumberAnimation { target: cell; property: "tilt"; to: 0; duration: 240; easing.type: Easing.OutBack }
            }

            Component.onCompleted: page = Planet.groupStart + index
        }
    }
}
