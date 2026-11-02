import QtQuick
import Quickshell
import qs.config
import qs.services

// The time up front, the date right next to it. A click opens the calendar.
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Row {
        id: row

        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.textSize + 6
            font.weight: Font.Medium
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.locale(Config.locale).toString(clock.date, "dddd d MMMM")
            color: Theme.textSoft
            font.family: Theme.font
            font.pixelSize: Theme.textSize
            font.letterSpacing: 0.3
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: Menus.togglePanel("left")
    }
}
