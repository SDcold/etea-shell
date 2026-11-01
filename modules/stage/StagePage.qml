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

    signal picked()

    transform: [
        Scale {
            origin.x: root.width / 2
            origin.y: root.height
            xScale: root.zoom
            yScale: root.zoom
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

    // Up in orbit every page is a button, even an empty one
    MouseArea {
        anchors.fill: parent
        enabled: Planet.orbiting
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
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
