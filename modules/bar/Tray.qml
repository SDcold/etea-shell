import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.services

// The apps running in the background. Left click opens them, right click shows their menu
// in one of ours.
Row {
    id: root

    readonly property bool wanted: SystemTray.items.values.length > 0

    spacing: Math.round(Theme.barSpacing * 0.7)

    Repeater {
        model: SystemTray.items

        Item {
            id: entry

            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            width: Theme.iconSize - 1
            height: Theme.iconSize - 1
            IconImage {
                id: picture

                anchors.fill: parent
                visible: !Config.trayTint
                source: entry.modelData.icon
                implicitSize: Theme.iconSize - 1
            }

            // In the shell's colours, they read like the rest of the bar
            MultiEffect {
                visible: Config.trayTint
                anchors.fill: parent
                source: picture
                colorization: 1
                colorizationColor: Theme.text
                brightness: 1
            }

            Hover {
                anchors.margins: -4
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onPressed: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                        entry.modelData.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton || entry.modelData.onlyMenu) {
                        if (entry.modelData.hasMenu) {
                            Menus.trayItem = entry.modelData;
                            Menus.toggle(`tray-${entry.modelData.id}`, entry.mapToItem(null, entry.width / 2, 0).x);
                        }
                    } else {
                        entry.modelData.activate();
                    }
                }
            }
        }
    }
}
