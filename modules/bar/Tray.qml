import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config

// The apps running in the background. Left click opens them, right click shows their menu.
Row {
    id: root

    visible: Config.status.includes("tray") && SystemTray.items.values.length > 0
    spacing: 12
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
        model: SystemTray.items

        Item {
            id: entry

            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            scale: pointer.containsMouse ? 1.18 : 1

            Behavior on scale {
                NumberAnimation { duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
            }

            IconImage {
                anchors.fill: parent
                source: entry.modelData.icon
                implicitSize: 20
            }

            MouseArea {
                id: pointer

                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                        entry.modelData.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton || entry.modelData.onlyMenu) {
                        if (entry.modelData.hasMenu) {
                            const spot = entry.mapToItem(null, 0, entry.height + 8);
                            entry.modelData.display(QsWindow.window, spot.x, spot.y);
                        }
                    } else {
                        entry.modelData.activate();
                    }
                }
            }
        }
    }
}
