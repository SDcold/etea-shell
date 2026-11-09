import QtQuick
import Quickshell
import qs.config
import qs.services

// The time, enormous, standing in the sky and dissolving as it sinks towards the
// mountains. It sits behind the terrain, so the hills really do pass in front of it.
Item {
    id: root

    property real sky: 1080
    property var options: ({}) // its entry in Config.widgets

    implicitWidth: digits.implicitWidth
    implicitHeight: digits.implicitHeight

    Text {
        visible: root.options?.date !== false
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: digits.top
        anchors.bottomMargin: -root.sky * 0.085
        text: Qt.locale(Config.locale).toString(Time.now, Lang.t("dddd d MMMM"))
        color: Desk.ink
        font.family: Theme.font
        font.pixelSize: root.sky * 0.03
        font.weight: Font.Medium
    }

    Text {
        id: digits

        text: Config.time(Time.now, { suffix: false })
        color: Desk.ink
        font.family: Theme.font
        font.pixelSize: root.sky * 0.54
        font.weight: Font.Medium
        font.letterSpacing: -root.sky * 0.01
        // Qt's usual text gets ragged edges this big, this draws the real letter outlines
        renderType: Text.CurveRendering

        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(width * 2, height * 2) // drawn at double size so the curves come out smooth
        layer.effect: Dissolve {}
    }
}
