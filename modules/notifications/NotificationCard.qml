import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.modules.bar
import qs.services

// One message from far away. Up on screen it arrives as a comet, in the journal
// it just sits there, and a click either way sends it off.
Item {
    id: root

    required property var entry
    property bool inJournal: false

    readonly property var notification: entry.notification
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property string picture: {
        if (notification?.image)
            return notification.image;
        if (notification?.appIcon)
            return notification.appIcon.includes("/") ? `file://${notification.appIcon}` : Quickshell.iconPath(notification.appIcon, true);
        return "";
    }

    property real arrival: inJournal ? 1 : 0

    width: Theme.notifWidth
    height: card.height

    function when() {
        const minutes = Math.floor((Date.now() - entry.time.getTime()) / 60000);
        if (minutes < 1)
            return "à l'instant";
        if (minutes < 60)
            return `il y a ${minutes} min`;
        return Qt.formatTime(entry.time, "HH:mm");
    }

    Component.onCompleted: {
        if (!inJournal) {
            comet.start();
            if (!critical)
                lifetime.start();
        }
    }

    // Time up: off it goes, and it stays in the journal
    Timer {
        id: lifetime

        interval: root.notification?.expireTimeout > 0 ? root.notification.expireTimeout : Theme.notifLife
        onTriggered: Notifs.hide(root.entry)
    }

    // The comet crosses in from the edge of the screen, then the card opens where it lands
    SequentialAnimation {
        id: comet

        ParallelAnimation {
            NumberAnimation {
                target: head
                property: "x"
                from: Theme.notifWidth + 220
                to: 14
                duration: Theme.notifComet
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: head
                property: "y"
                from: -46
                to: 26
                duration: Theme.notifComet
                easing.type: Easing.OutCubic
            }
        }
        NumberAnimation {
            target: root
            property: "arrival"
            from: 0
            to: 1
            duration: Theme.notifOpen
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: card

        width: parent.width
        height: content.implicitHeight + 28
        radius: 18
        color: Theme.notifCard
        border.width: 1
        border.color: Qt.alpha(Theme.windowLit, root.critical ? 0.8 : 0.26)
        opacity: root.arrival
        clip: true

        transform: Translate {
            x: (1 - root.arrival) * 34
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: mouse => mouse.button === Qt.RightButton || root.inJournal ? Notifs.dismiss(root.entry) : Notifs.hide(root.entry)
        }

        RowLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            Image {
                visible: root.picture !== ""
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                sourceSize: Qt.size(92, 92)
                fillMode: Image.PreserveAspectCrop
                source: root.picture
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: root.notification?.appName ?? ""
                        elide: Text.ElideRight
                        color: Theme.windowLit
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.letterSpacing: 0.4
                    }

                    Text {
                        text: root.when()
                        color: Qt.alpha(Theme.text, 0.5)
                        font.family: Theme.font
                        font.pixelSize: 12
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.notification?.summary ?? ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 17
                }

                Text {
                    visible: text !== ""
                    Layout.fillWidth: true
                    text: root.notification?.body ?? ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    color: Qt.alpha(Theme.text, 0.72)
                    font.family: Theme.font
                    font.pixelSize: 14
                }

                Row {
                    visible: (root.notification?.actions.length ?? 0) > 0
                    Layout.topMargin: 6
                    spacing: 14

                    Repeater {
                        model: root.notification?.actions ?? []

                        Text {
                            required property var modelData

                            text: modelData.text
                            color: Theme.windowLit
                            font.family: Theme.font
                            font.pixelSize: 14

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onPressed: parent.modelData.invoke()
                            }
                        }
                    }
                }
            }
        }
    }

    // The head of the comet, trailing light behind it
    Item {
        id: head

        visible: !root.inJournal && root.arrival < 1
        opacity: 1 - root.arrival

        Rectangle {
            x: 0
            y: -1
            width: 150
            height: 2
            rotation: -18
            transformOrigin: Item.Left
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(Theme.starGlow, 0.85) }
                GradientStop { position: 1; color: Qt.alpha(Theme.starGlow, 0) }
            }
        }

        Star {
            x: -size
            y: -size
            size: 13
            lit: true
            animated: false
        }
    }
}
