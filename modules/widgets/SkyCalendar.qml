import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.modules.bar

// The month written on the sky, with tonight's moon beside its name.
ColumnLayout {
    id: root

    property real sky: 1080
    property var options: ({})

    spacing: sky * 0.01
    width: sky * 0.27

    RowLayout {
        Layout.fillWidth: true
        spacing: root.sky * 0.012

        Text {
            Layout.fillWidth: true
            text: Qt.locale(Config.locale).toString(Time.now, "MMMM")
            color: Desk.ink
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
            at: Time.now
            dark: Qt.alpha(Desk.ink, 0.18)
            light: Desk.ink
        }
    }

    Text {
        text: moon.phaseName
        color: Qt.alpha(Desk.ink, 0.7)
        font.family: Theme.font
        font.pixelSize: root.sky * 0.013
    }

    MonthGrid {
        Layout.fillWidth: true
        month: Time.now
        today: Time.now
        unit: root.sky * 0.016
        ink: Desk.ink
        heading: Qt.alpha(Desk.ink, 0.6)
    }
}
