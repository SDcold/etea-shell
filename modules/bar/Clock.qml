import QtQuick
import Quickshell
import qs.config
import qs.services

// The time up front, the date right next to it.
Row {
    id: root

    spacing: 12
    anchors.verticalCenter: parent.verticalCenter

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.textSize + 8
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.locale(Config.locale).toString(clock.date, "dddd d MMMM")
        color: Theme.textSoft
        font.family: Theme.font
        font.pixelSize: Theme.textSize
    }

    // The whole clock opens the calendar
    Item {
        width: 0
        height: 0

        MouseArea {
            x: -root.width
            y: -root.height / 2
            width: root.width
            height: root.height
            cursorShape: Qt.PointingHandCursor
            onPressed: Menus.toggle("calendar", root.mapToItem(null, root.width / 2, 0).x)
        }
    }
}
