import QtQuick
import qs.config
import qs.services

// All the stand-ins of one page. They turn together around the planet.
Item {
    id: root

    required property var windows
    required property real pivotY
    required property real screenX
    required property real screenY
    property real angle: 0
    property Item photo: null
    property real zoom: 1 // how small the page is, seen from above
    property real lift: 0 // how far up it rides with the ground
    property bool orbitCard: false // the pages around the planet, as opposed to the ones spinning past

    property bool pointedAt: false
    property real boost: pointedAt ? 1.16 : 1

    Behavior on boost {
        NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
    }

    transform: [
        Scale {
            origin.x: root.width / 2
            origin.y: root.height
            xScale: root.zoom * root.boost
            yScale: root.zoom * root.boost
        },
        Translate {
            y: root.lift
        },
        Rotation {
            origin.x: root.width / 2
            origin.y: root.pivotY
            angle: root.angle * 180 / Math.PI
        }
    ]

    // An empty page still needs to be there, so you can see where to land
    Rectangle {
        visible: root.orbitCard && root.windows.length === 0
        anchors.fill: parent
        anchors.margins: Theme.windowGapOuter
        anchors.topMargin: Theme.barGap + Theme.barHeight + Theme.windowGapOuter
        radius: Theme.windowRadius
        color: Qt.alpha(Theme.windowLit, 0.04)
        border.width: 6
        border.color: Qt.alpha(Theme.windowLit, 0.28)
    }

    Repeater {
        model: root.windows

        WindowDouble {
            required property var modelData
            required property int index

            // The list ends with the most recently used window, the one that's lit
            lit: index === root.windows.length - 1
            toplevel: modelData
            photo: root.photo
            screenX: root.screenX
            screenY: root.screenY
        }
    }
}
