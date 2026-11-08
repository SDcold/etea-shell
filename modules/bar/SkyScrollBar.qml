import QtQuick
import QtQuick.Controls
import qs.config

// A scroll bar in ETEA's ink: a faint thread, and on it a lit stroke with a star that you
// can grab. It only shows when there's somewhere to scroll.
ScrollBar {
    id: root

    policy: size < 1 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    padding: 0
    minimumSize: 0.08 // long enough to grab, however many pictures there are
    implicitWidth: 18

    background: Item {
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 1
            height: parent.height
            color: Qt.alpha(Theme.text, 0.14)
        }
    }

    contentItem: Item {
        implicitWidth: 18
        implicitHeight: 40

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.pressed || root.hovered ? 3 : 2
            height: parent.height
            radius: width / 2
            color: Qt.alpha(Theme.windowLit, root.pressed ? 0.95 : root.hovered ? 0.8 : 0.55)

            Behavior on width {
                NumberAnimation { duration: Theme.fast }
            }
        }

        Star {
            anchors.centerIn: parent
            size: root.pressed || root.hovered ? 6 : 4.5
            lit: true
            animated: false

            Behavior on size {
                NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic }
            }
        }
    }
}
