import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.bar
import qs.modules.stage
import qs.services

// The settings page. It's a real window, so it's born from a star and gets its frame
// like any other. Sections are a constellation down the side, every change applies live.
Scope {
    FloatingWindow {
        id: window

        title: "Réglages ETEA"
        visible: Menus.settingsOpen
        implicitWidth: 1040
        implicitHeight: 700
        color: Theme.cardDeep

        onVisibleChanged: {
            if (!visible)
                Menus.settingsOpen = false;
            else
                body.arrive();
        }

        SettingsBody {
            id: body

            anchors.fill: parent
            showing: window.visible
        }
    }
}
