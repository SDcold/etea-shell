import QtQuick
import qs.config
import qs.modules.bar
import qs.services

Text {
    id: root

    color: Menus.tint
    font.family: Theme.font
    font.pixelSize: 11
    font.letterSpacing: 0.5

    Entrance {
        item: root
    }
}
