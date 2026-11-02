import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

// The menu a background app offers, drawn like every other menu here.
// Submenus open in place, with a way back at the top.
ColumnLayout {
    id: root

    readonly property var app: Menus.trayItem
    property var trail: [] // the submenus we went down into
    readonly property var current: trail.length ? trail[trail.length - 1] : app?.menu ?? null

    spacing: 2
    width: 280

    // The app quit while its menu was open
    onAppChanged: {
        if (!app)
            Menus.close();
    }

    QsMenuOpener {
        id: opener

        menu: root.current
    }

    MenuTitle {
        Layout.bottomMargin: 4
        text: root.trail.length ? root.trail[root.trail.length - 1].text : root.app?.title || root.app?.id || ""
    }

    MenuRow {
        visible: root.trail.length > 0
        Layout.fillWidth: true
        label: `‹  ${Lang.t("Retour")}`
        onPicked: root.trail = root.trail.slice(0, -1)
    }

    Repeater {
        model: opener.children

        Loader {
            id: entry

            required property var modelData

            Layout.fillWidth: true
            sourceComponent: modelData.isSeparator ? line : row

            Component {
                id: line

                Item {
                    implicitHeight: 9

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        width: parent.width - 16
                        height: 1
                        color: Qt.alpha(Theme.text, 0.12)
                    }
                }
            }

            Component {
                id: row

                MenuRow {
                    readonly property var choice: entry.modelData

                    enabled: choice.enabled
                    opacity: enabled ? 1 : 0.4
                    label: choice.text.replace(/_(?!_)/g, "") // underscores mark keyboard accelerators
                    active: choice.buttonType !== QsMenuButtonType.None && choice.checkState === Qt.Checked
                    detail: choice.hasChildren ? "›" : ""
                    onPicked: {
                        if (choice.hasChildren) {
                            root.trail = root.trail.concat([choice]);
                        } else {
                            choice.triggered();
                            Menus.close();
                        }
                    }
                }
            }
        }
    }
}
