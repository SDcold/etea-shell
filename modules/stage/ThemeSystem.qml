import QtQuick
import qs.config
import qs.modules.bar
import qs.services

// The top of the climb: every world you could live on, hanging in space. The one you're
// looking at comes forward. Landing on it makes it home.
Item {
    id: root

    readonly property real level: Planet.systemLevel
    readonly property var chosen: Planets.all[Planet.systemChoice]

    opacity: level
    visible: level > 0.01

    Repeater {
        model: Planets.all

        Item {
            id: world

            required property var modelData
            required property int index

            readonly property int offset: {
                const count = Planets.all.length;
                let distance = (index - Planet.systemChoice + count) % count;
                return distance > count / 2 ? distance - count : distance;
            }
            readonly property bool front: offset === 0

            width: 440
            height: 440
            x: root.width / 2 - width / 2 + offset * root.width * 0.3
            y: root.height * 0.44 - height / 2
            z: front ? 2 : 1
            scale: (front ? 1 : 0.42) * (0.82 + 0.18 * root.level)
            opacity: Math.abs(offset) > 1 ? 0.3 : 1

            Behavior on x {
                NumberAnimation { duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
            }
            Behavior on scale {
                NumberAnimation { duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.expressive }
            }

            PlanetView {
                anchors.fill: parent
                planet: world.modelData
                spinning: root.visible
            }

            MouseArea {
                anchors.centerIn: parent
                width: 360
                height: 360
                enabled: Planet.inSystem
                cursorShape: Qt.PointingHandCursor
                onPressed: world.front ? Planet.land(world.modelData.id) : Planet.chooseStep(world.offset)
            }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.74
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.chosen.name
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 34
            font.weight: Font.Light
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.chosen.line
            color: Qt.alpha(Theme.text, 0.7)
            font.family: Theme.font
            font.pixelSize: 15
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 12
            text: root.chosen.id === Theme.planet.id ? "Tu vis ici" : "Entrée pour t'y poser"
            color: root.chosen.light
            font.family: Theme.font
            font.pixelSize: 13
        }
    }
}
