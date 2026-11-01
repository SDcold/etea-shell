import QtQuick
import qs.config

// All the stand-ins of one page. They turn together around the planet.
Item {
    id: root

    required property var windows
    required property real pivotY
    required property real screenX
    required property real screenY
    property real angle: 0
    property Item photo: null

    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.pivotY
        angle: root.angle * 180 / Math.PI
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
