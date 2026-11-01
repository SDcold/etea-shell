import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.config
import qs.services

// Signals from far away. They land in the top right corner, and stay in the
// journal until you clear them.
Scope {
    NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: notification => {
            notification.tracked = true;
            Notifs.add(notification);
        }
    }

    IpcHandler {
        target: "notifications"

        function journal(): void {
            Notifs.journalOpen = !Notifs.journalOpen;
        }

        function clear(): void {
            Notifs.clear();
        }
    }

    PanelWindow {
        id: panel

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: Notifs.popups.length > 0 || Notifs.journalOpen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: Theme.notifWidth + 40
        implicitHeight: screen.height - Theme.barGap - Theme.barHeight
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "etea:notifications"
        margins.top: Theme.barGap + Theme.barHeight + 6

        anchors {
            top: true
            right: true
        }

        // Only the cards catch the mouse, the rest of the column stays usable
        mask: Region {
            Region { item: stack }
        }

        Column {
            id: stack

            x: 20
            y: 10
            spacing: 16

            // The journal: every message still waiting for you
            Text {
                visible: Notifs.journalOpen
                width: Theme.notifWidth
                text: Notifs.count ? "Effacer tout" : "Aucun signal."
                horizontalAlignment: Text.AlignRight
                color: Theme.text
                style: Text.Outline
                styleColor: Qt.alpha("#000000", 0.3)
                font.family: Theme.font
                font.pixelSize: 13

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: Notifs.clear()
                }
            }

            Repeater {
                model: Notifs.journalOpen ? Notifs.log.slice(0, 6) : []

                NotificationCard {
                    required property var modelData

                    entry: modelData
                    inJournal: true
                }
            }

            Repeater {
                model: Notifs.journalOpen ? [] : Notifs.popups

                NotificationCard {
                    required property var modelData

                    entry: modelData
                }
            }
        }
    }
}
