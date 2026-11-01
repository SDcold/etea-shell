import QtQuick
import Quickshell
import qs.config

// The time, enormous, standing in the sky and dissolving as it sinks towards the
// mountains. It sits behind the terrain, so the hills really do pass in front of it.
Item {
    id: root

    property real sky: 1080

    implicitWidth: digits.implicitWidth
    implicitHeight: digits.implicitHeight

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: digits.top
        anchors.bottomMargin: -root.sky * 0.085
        text: Qt.locale(Config.locale).toString(clock.date, "dddd d MMMM")
        color: Theme.skyInk
        font.family: Theme.font
        font.pixelSize: root.sky * 0.03
        font.weight: Font.Medium
    }

    Text {
        id: digits

        text: Qt.formatTime(clock.date, "HH:mm")
        color: Theme.skyInk
        font.family: Theme.font
        font.pixelSize: root.sky * 0.54
        font.weight: Font.Medium
        font.letterSpacing: -root.sky * 0.01

        layer.enabled: true
        layer.effect: Dissolve {}
    }
}
