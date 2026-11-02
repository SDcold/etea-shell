import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.bar

// The month written on the sky, with tonight's moon beside its name.
ColumnLayout {
    id: root

    property real sky: 1080
    property var options: ({})

    spacing: sky * 0.01
    width: sky * 0.27

    SystemClock {
        id: clock

        precision: SystemClock.Hours
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: root.sky * 0.012

        Text {
            Layout.fillWidth: true
            text: Qt.locale(Config.locale).toString(clock.date, "MMMM")
            color: Theme.skyInk
            font.family: Theme.font
            font.pixelSize: root.sky * 0.034
            font.weight: Font.Medium
            renderType: Text.CurveRendering

            layer.enabled: true
            layer.smooth: true
            layer.textureSize: Qt.size(width * 2, height * 2) // drawn at double size so the curves come out smooth
            layer.effect: Dissolve {
                from: 0.4
                to: 1.3
            }
        }

        MoonDisc {
            id: moon

            Layout.preferredWidth: Math.round(root.sky * 0.028)
            Layout.preferredHeight: Math.round(root.sky * 0.028)
            at: clock.date
            dark: Qt.alpha(Theme.skyInk, 0.18)
            light: Theme.skyInk
        }
    }

    Text {
        text: moon.phaseName
        color: Qt.alpha(Theme.skyInk, 0.7)
        font.family: Theme.font
        font.pixelSize: root.sky * 0.013
    }

    MonthGrid {
        Layout.fillWidth: true
        month: clock.date
        today: clock.date
        unit: root.sky * 0.016
        ink: Theme.skyInk
        heading: Qt.alpha(Theme.skyInk, 0.6)
    }
}
