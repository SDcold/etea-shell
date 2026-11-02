import QtQuick
import qs.config
import qs.modules.bar
import qs.services

// What you have to do, written on the sky. Each task is a star you can tick, and it
// lights up once it's done, the same list as in the logbook.
Column {
    id: root

    property real sky: 1080
    property var options: ({})
    readonly property int most: 7

    spacing: sky * 0.008
    width: sky * 0.28

    Text {
        text: Tasks.items.length ? `${Lang.t("Tâches")} · ${Tasks.items.filter(task => !task.done).length}` : Lang.t("Tâches")
        color: Qt.alpha(Theme.skyInk, 0.8)
        font.family: Theme.font
        font.pixelSize: root.sky * 0.016
        font.weight: Font.Medium
    }

    Repeater {
        model: Tasks.items.slice(0, root.most)

        Item {
            id: task

            required property var modelData
            required property int index

            width: root.width
            height: label.implicitHeight + root.sky * 0.008

            Star {
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                size: root.sky * 0.0075
                lit: task.modelData.done
                animated: false
                opacity: task.modelData.done ? 1 : 0.5
            }

            Text {
                id: label

                x: root.sky * 0.026
                width: parent.width - x
                anchors.verticalCenter: parent.verticalCenter
                text: task.modelData.text
                elide: Text.ElideRight
                font.strikeout: task.modelData.done
                color: task.modelData.done ? Qt.alpha(Theme.skyInk, 0.45) : Theme.skyInk
                font.family: Theme.font
                font.pixelSize: root.sky * 0.021
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: Tasks.toggle(task.index)
            }
        }
    }

    Text {
        visible: Tasks.items.length > root.most
        text: `+ ${Tasks.items.length - root.most}`
        color: Qt.alpha(Theme.skyInk, 0.6)
        font.family: Theme.font
        font.pixelSize: root.sky * 0.014
    }

    Text {
        visible: Tasks.items.length === 0
        width: root.width
        text: Lang.t("Rien à faire. Le ciel est à toi.")
        wrapMode: Text.WordWrap
        color: Theme.skyInk
        font.family: Theme.font
        font.pixelSize: root.sky * 0.02
    }

    Text {
        visible: Tasks.items.length === 0
        width: root.width
        text: Lang.t("Ajoute-en dans le panneau de gauche, Super + A.")
        wrapMode: Text.WordWrap
        color: Qt.alpha(Theme.skyInk, 0.6)
        font.family: Theme.font
        font.pixelSize: root.sky * 0.013
    }
}
