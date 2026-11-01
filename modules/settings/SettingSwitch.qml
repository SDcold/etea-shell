import QtQuick
import qs.modules.bar.menus

// On or off.
SettingRow {
    id: root

    property bool on: false

    signal toggled()

    MenuSwitch {
        on: root.on
        onToggled: root.toggled()
    }
}
