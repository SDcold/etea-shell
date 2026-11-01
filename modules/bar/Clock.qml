import QtQuick
import Quickshell
import qs.config

// The time up front, the date right next to it.
Row {
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
}
