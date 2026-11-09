import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services
import qs.modules.bar

// A picture of your own, hung in the sky like one more window. It melts away towards
// the hills the way the time does.
Item {
    id: root

    property real sky: 1080
    property var options: ({})
    readonly property string image: options?.image ?? ""
    readonly property real ratio: picture.status === Image.Ready ? picture.implicitHeight / Math.max(1, picture.implicitWidth) : 0.66

    implicitWidth: sky * 0.34
    implicitHeight: image ? implicitWidth * ratio : sky * 0.14

    ClippingRectangle {
        visible: root.image !== ""
        anchors.fill: parent
        radius: root.sky * 0.018
        color: "transparent"

        layer.enabled: true
        layer.effect: Dissolve {
            from: 0.62
            to: 1.12
        }

        Image {
            id: picture

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: root.width * 2
            source: root.image ? `file://${root.image}` : ""
        }
    }

    // Nothing chosen yet: say how
    Column {
        visible: root.image === ""
        anchors.centerIn: parent
        spacing: root.sky * 0.008

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "image"
            size: Math.round(root.sky * 0.034)
            tint: Qt.alpha(Desk.ink, 0.7)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Lang.t("Clic droit pour choisir une image.")
            color: Qt.alpha(Desk.ink, 0.7)
            font.family: Theme.font
            font.pixelSize: root.sky * 0.014
        }
    }
}
