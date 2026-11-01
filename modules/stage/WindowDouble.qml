import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services

// A stand-in for one window. Cut out of the page's photo whenever we have one,
// which makes it identical to the real thing. Otherwise a plain window capture.
Item {
    id: root

    required property var toplevel
    required property real screenX
    required property real screenY
    property Item photo: null
    property bool lit: false

    // A window can close mid-spin and take its details with it
    readonly property var info: toplevel?.lastIpcObject?.size ? toplevel.lastIpcObject : ({ at: [0, 0], size: [0, 0] })
    readonly property int edge: Theme.traceWidth

    x: info.at[0] - screenX - edge
    y: info.at[1] - screenY - edge
    width: info.size[0] + edge * 2
    height: info.size[1] + edge * 2

    // The glow spills past the window, so the photo can't carry it along
    WindowGlow {
        visible: root.lit
        anchors.fill: parent
        anchors.margins: -Theme.windowGlowSize
        window: Qt.size(root.info.size[0], root.info.size[1])
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.windowRadius + root.edge
        color: "transparent"

        ShaderEffectSource {
            visible: root.photo !== null
            anchors.fill: parent
            sourceItem: root.photo
            sourceRect: Qt.rect(root.x, root.y, root.width, root.height)
            live: false
        }

        Loader {
            active: root.photo === null
            anchors.fill: parent
            anchors.margins: root.edge

            sourceComponent: ScreencopyView {
                captureSource: root.toplevel?.wayland ?? null
                live: false
                onHasContentChanged: {
                    if (hasContent)
                        Planet.noteCaptured();
                }
            }
        }
    }

    // Photos already have their border, only the plain capture needs one drawn
    Rectangle {
        visible: root.photo === null
        anchors.fill: parent
        radius: Theme.windowRadius + root.edge
        color: "transparent"
        border.width: root.edge
        border.color: Qt.alpha(Theme.windowLit, root.lit ? Theme.traceLine : Theme.windowRestBorder)
    }

    // A window keeps its frame on the way round
    FrameStars {
        visible: root.lit
        anchors.fill: parent
        anchors.margins: root.edge
        seed: root.toplevel?.address ?? ""
        windowWidth: root.info.size[0]
        windowHeight: root.info.size[1]
    }
}
