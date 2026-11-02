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

        precision: Config.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Row {
        id: row

        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(clock.date, (Config.clockFormat === "12" ? "h:mm" : "HH:mm") + (Config.clockSeconds ? ":ss" : "") + (Config.clockFormat === "12" ? " AP" : ""))
            font.features: { "tnum": 1 }
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.textSize + 6
            font.weight: Font.Medium
        }

        Text {
            visible: Config.dateFormat !== "off"
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.locale(Config.locale).toString(clock.date, Config.dateFormat === "short" ? "ddd d MMM" : "dddd d MMMM")
            color: Theme.textSoft
            font.family: Theme.font
            font.pixelSize: Theme.textSize
            font.letterSpacing: 0.3
        }
    }

    Hover {
        onPressed: Menus.togglePanel("left")
    }
}
