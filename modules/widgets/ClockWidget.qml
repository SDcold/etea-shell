import QtQuick
import Quickshell
import qs.config

// The big clock in the sky, for when the page is empty.
Column {
    spacing: -6

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 132
        style: Text.Raised
        styleColor: Qt.alpha("#000000", 0.14)
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.locale(Config.locale).toString(clock.date, "dddd d MMMM")
        color: Theme.textSoft
        font.family: Theme.font
        font.pixelSize: 26
    }
}
